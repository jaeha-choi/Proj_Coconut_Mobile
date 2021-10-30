import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/encryption/rsa.dart';
import 'package:mobile_app/utils/contact_class.dart';
import 'package:mobile_app/utils/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/commands.dart';
import 'utils/error.dart';

final logger = Logger(
  printer: PrettyPrinter(
      noBoxingByDefault: true,
      // number of method calls to be displayed
      methodCount: 0,
      // number of method calls if stacktrace is provided
      errorMethodCount: 3,
      // width of the output
      lineLength: 50,
      // Colorful log messages
      colors: true,
      // Print an emoji for each log message
      printEmojis: true,
      // Should each log print contain a timestamp
      printTime: false),
);

class Message {
  final int size;
  final Error errorCode;
  final Command command;
  final Uint8List data;

  const Message(this.size, this.errorCode, this.command, this.data);
}

class Client {
  String serverIP;
  int serverPort;
  late SecureSocket conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;
  Map<String, StreamController<Message>> mapOfChannel;

  Client({
    required String serverIP,
    required int serverPort,
    // SecureSocket? conn,
    required RSAPrivateKey privKey,
    required String pubKey,
    required String addCode,
    required Map<String, StreamController<Message>> mapOfChannel,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        // this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode,
        this.mapOfChannel = mapOfChannel;

  late SharedPreferences sharedPreferences;

  List<User> friendsList = <User>[];

  /// Connects to the server
  /// Returns [Error] ExistingConnError if there is error in connection
  Future<Error> connect() async {
    try {
      logger.i('Connecting....');
      this.conn = await SecureSocket.connect(
        this.serverIP,
        this.serverPort,
        onBadCertificate: (certificate) =>
            true, // TODO: Change once dev. is done
      );

      // Add listen method
      this.conn.listen((Uint8List data) {
        // handle data from the server
        commandHandler(data);
      });

      logger.i(
          'Connected to ${this.conn.remoteAddress.address}:${this.conn.remotePort}');
    } catch (e) {
      logger.e('Error in connect() :$e');
      return ExistingConnError;
    }

    // Initializing client
    return await doInit();
  }

  /// Send initialization code [pubKeyHash] to the server
  Future<Error> doInit() async {
    final Command comm = Init;
    // Creates map of command
    this.mapOfChannel[comm.string] = StreamController<Message>();

    final StreamIterator<Message> iter =
        StreamIterator<Message>(this.mapOfChannel[comm.string]!.stream);
    Uint8List pubKeyHash = pemToSha256(this.pubKeyBlock);
    // Send pubKeyHash to the server
    if (writeBytes(this.conn, pubKeyHash, comm, NoError) == -1) {
      logger.d("Error in doInit()");
      // Remove channel if error is encountered
      this.mapOfChannel.remove(comm.string);
      return WritingMsgError;
    }
    // Send local address
    var temp = await NetworkInterface.list();
    // Currently, we're just assuming the first element to have the
    // correct local ip address
    String ipPort = temp[0].addresses[0].address + ":${this.conn.port}";
    if (writeString(this.conn, ipPort, comm, NoError) == -1) {
      logger.d("Error in doInit()");
      this.mapOfChannel.remove(comm.string);
      return WritingMsgError;
    }
    return await getResult(comm.string, iter);
  }

  /// Returns error code from the server
  /// getResults get called every feature calls to check potential error
  Future<Error> getResult(String command, StreamIterator<Message> iter) async {
    Message msg = await readBytes(iter);
    this.mapOfChannel.remove(command);
    return msg.errorCode;
  }

  /// Remove Add Code
  /// It removes AddCode from server, if it success return [Error] NoError
  /// otherwise return [Error] UnknownError
  Future<Error> doRemoveAddCode() async {
    final Command comm = RemoveAddCode;
    try {
      // Creates a map to store incoming data
      this.mapOfChannel[comm.string] = StreamController<Message>();
      final StreamIterator<Message> iter =
          StreamIterator<Message>(this.mapOfChannel[comm.string]!.stream);
      // Send the remove add code command
      if (writeString(this.conn, comm.string, comm, NoError) == -1) {
        logger.d("Error while sending command(Remove Add Code) to the server");
      }
      // send the add code that you want to erase
      if (writeString(this.conn, this.addCode, comm, NoError) == -1) {
        logger.d("Error while sending free add code to the server");
      }

      // Erase add code front client
      this.addCode = "";

      return await getResult(comm.string, iter);
    } catch (e) {
      logger.e("Error in doRemoveAddCode: $e");
      this.mapOfChannel.remove(comm.string);
      return GeneralClientError;
    }
  }

  /// Sends command(Get Add Code)
  /// Returns [Error] GeneralClientError if there is no Add code available
  Future<Error> doGetAddCode() async {
    final Command comm = GetAddCode;
    this.mapOfChannel[comm.string] = StreamController<Message>();
    final StreamIterator<Message> iter =
        StreamIterator<Message>(this.mapOfChannel[comm.string]!.stream);
    // Send the command to the server
    try {
      if (writeString(this.conn, comm.string, comm, NoError) == -1) {
        logger.d("Error while sending command(get Add Code) to the server");
      }
      Message msg = await readBytes(iter);
      // Error checking. Do check every Message
      if (msg.errorCode.code != 0) {
        return msg.errorCode;
      }
      this.addCode = utf8.decode(msg.data);
      return await getResult(comm.string, iter);
    } catch (e) {
      // General error checking
      logger.e("Error in doGetAddCode: $e");
      this.mapOfChannel.remove(comm.string);
      return GeneralClientError;
    }
  }

  /// Sends the recipient's AddCode to the server to receive recipient's pubKey.
  /// If it is successful, it saves recipient information locally using _save()
  /// Returns [Error] clientNotFoundError if no client found
  Future<List> doRequestPubKey(String recipientAddCode, String fullName) async {
    final Command comm = GetPubKey;
    // Creates map to store data from the server
    this.mapOfChannel[comm.toString()] = StreamController<Message>();
    final StreamIterator<Message> iter =
        StreamIterator<Message>(this.mapOfChannel[comm.string]!.stream);
    // Send the command to the server
    try {
      if (writeBytes(this.conn, Uint8List(0), comm, NoError) == -1) {
        logger
            .d("Error while sending command(request public key) to the server");
      }
      if (writeString(this.conn, recipientAddCode, comm, NoError) == -1) {
        logger.d("Error while sending recipient AddCode to the server");
      }
      Message msg = await readBytes(iter);
      // Check error checking
      if (msg.errorCode.code != 0) {
        return [ClientNotFoundError, ''];
      }
      String pubKeyString = utf8.decode(msg.data);
      // _save(fullName, pubKeyString);
      return [await getResult(comm.string, iter), pubKeyString];
    } catch (e) {
      logger.e("Error in doRequestPubKey: $e");
      this.mapOfChannel.remove(comm.string);
      return [ClientNotFoundError, ''];
    }
  }

  /// Command Handler gets called Right after connect to the server
  /// Command Handler will write data to [client.mapOfChannel]
  void commandHandler(Uint8List inputData) {
    int size = -1;
    int errorCode = UnknownCodeError.code;
    int commandCode = inputData[5];
    Uint8List data = Uint8List(0);

    size = bytesToUint32(inputData);
    errorCode = inputData[4];
    if (errorCode != 0) {
      // if errorCode is not in Error class, then return unknown Error
      if (!errorsList.asMap().containsKey(errorCode)) {
        errorCode = UnknownCodeError.code;
      }
    }
    // If the packets can be trimmed before received, check if the size of
    // received data matches the size of the original msg
    if (size != 0) {
      data = inputData.sublist(6);
    }
    Message msg =
        Message(size, errorsList[errorCode], commandsList[commandCode], data);
    this.mapOfChannel[commandsList[commandCode].string]!.add(msg);
  }

  Future<void> close() async {
    await this.conn.close();
  }
}

/// Creates new [Client] and return it.
/// Returns null upon error.
Future<Client> newClient() async {
  // Open RSA keys, if the user already got one
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  bool isPub = File('$appDocPath/key.pub').existsSync();
  bool isPriv = File('$appDocPath/key.priv').existsSync();

  // If at least one key is not found, create new key pairs
  if (!(isPub && isPriv)) {
    await createPemFile(appDocPath);
  }

  // Public key needs to be in a string format
  String pubKey = File('$appDocPath/key.pub').readAsStringSync();
  // Private key needs to be in a PEM format
  RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(
      File('$appDocPath/key.priv').readAsStringSync());

  return new Client(
    serverIP: "127.0.0.1",
    serverPort: 9129,
    // conn: null,
    privKey: privateKey,
    pubKey: pubKey,
    addCode: "",
    mapOfChannel: new Map<String, StreamController<Message>>(),
  );
}

Future<void> main() async {
  Logger.level = Level.debug;
  Client client = await newClient();
  await client.connect();
}
