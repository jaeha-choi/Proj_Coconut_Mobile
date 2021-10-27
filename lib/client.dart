import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/encryption/rsa.dart';
import 'package:mobile_app/utils/util.dart';
import 'package:path_provider/path_provider.dart';

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

class Client {
  String serverIP;
  int serverPort;
  late SecureSocket conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;

  // late StreamIterator connDataIterator;
  Map<String, StreamController<Uint8List>> mapOfChannel;

  Client({
    required String serverIP,
    required int serverPort,
    // SecureSocket? conn,
    required RSAPrivateKey privKey,
    required String pubKey,
    required String addCode,
    required Map<String, StreamController<Uint8List>> mapOfChannel,
    // StreamSubscription? stream,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        // this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode,
        this.mapOfChannel = mapOfChannel;

// this.stream = stream;

  /// Connects to the server
  /// Returns true if connected to the server, false otherwise.
  Future<void> connect() async {
    try {
      logger.i('Connecting....');
      this.conn = await SecureSocket.connect(
        this.serverIP,
        this.serverPort,
        onBadCertificate: (certificate) => true,
      );

      // this.connDataIterator = StreamIterator(this.conn);

      // Add listen method
      this.conn.listen((Uint8List data) {
        // handle data from the server
        commandHandler(data);
      });

      logger.i(
          'Connected to ${this.conn.remoteAddress.address}:${this.conn.remotePort}');
    } catch (e) {
      logger.e('Error in connect() :$e');
    }
    // Initializing client
    await doInit();

    // return await doInit();
  }

  /// Send initialization code to the server
  Future<Error> doInit() async {
    this.mapOfChannel['INIT'] = StreamController<Uint8List>();
    Uint8List pubKeyHash = pemToSha256(this.pubKeyBlock);
    // Send pubKeyHash to the server
    if (writeBytes(this.conn, pubKeyHash) == -1) {
      logger.d("Error in doInit()");
    }
    return await getResult('INIT');
  }

  /// Returns error code from the server
  Future<Error> getResult(String command) async {
    Message msg =
        await readBytes(StreamIterator(this.mapOfChannel[command]!.stream));
    // Message msg = await readBytes2(StreamIterator(this.listOfChannel['ER']));
    // msg.data;
    return msg.errorCode;
  }

  /// Remove Add Code
  Future<void> doRemoveAddCode() async {
    try {
      // Send the remove add code command
      int err = writeString(this.conn, command(RemoveAddCode));
      if (err == -1) {
        logger.d("Error while sending command(Remove Add Code) to the server");
      }
      // send the add code that you want to erase
      int err2 = writeString(this.conn, this.addCode);
      if (err2 == -1) {
        logger.d("Error while sending free add code to the server");
      }

      // Erase add code front client
      this.addCode = '';

      // await getResult();
    } catch (e) {
      logger.e("Error in doRemoveAddCode: $e");
    }
  }

  /// Sends command(Get Add Code)
  Future<void> doGetAddCode() async {
    // Send the command to the server
    try {
      // creates BytesBuilder to store
      // Stream addCodeBuffer = ;
      // addCodeBuffer to client.listOfChannel
      // this.listOfChannel['AC'] = addCodeBuffer;
      writeString(this.conn, GetAddCode);
      logger.i("writeString command (DoGetcode()) is done");
      // Future check to see if addCodeBuffer is finished

    } catch (e) {
      logger.e("Error in doGetAddCode: $e");
      // return false;
    }
  }

  /// Command Handler gets called Right after connect to the server
  /// Command Handler will write data to [client.mapOfChannel]
  Future<void> commandHandler(Uint8List data) async {
    // Add code
    print(data);
    print("yo");
    if (data[0] == 0) {
      // TODO Change [StreamController<Uint8List>] change it to Stream?
      // initialize StreamController<Uint8List> inside of feature method
      Error err = await getResult('ER');
      print(err.errorCode);
    }

    // if ( == 'GADC') {
    //   // Creates ByteBuilder
    //   await this.doGetAddCode(eachCommand.command);
    //   // Add data to client.listOfChannel
    //   Message msg = await readBytes(this.connDataIterator);
    //   print(utf8.decode(msg.data));
    //   this.listOfChannel['AC'] = msg.data;
    //   // print(listOfChannel);
    //   this.addCode = utf8.decode(this.listOfChannel['AC'].takeByte());
    // }
  }
}

/// Creates new [Client] and return it.
/// Returns null upon error.
Future<Client> newClient() async {
  // try {
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
    mapOfChannel: new Map<String, StreamController<Uint8List>>(),

    // stream: null,
  );
}
// catch (e) {
//   logger.e('Error in newClient() $e');
// }
// return null;

Future<Client> createClient() async {
  Client client = await newClient();
  if (client == null) {
    //     TODO: Error handling
    print("Client is null");
  }
  await client.connect();
  // var connDataIterator = StreamIterator(client.listOfChannel['ER']);
  // print(connDataIterator.current);

  // diff thread
  // commandHandler(client, eachCommand)
  //    TODO need to change list of command
  // await client.doGetAddCode( );
  return client;
}

Future<void> main() async {
  Logger.level = Level.debug;
  Client? client = await newClient();
  if (client == null) {
    // TODO: Error handling
    return;
  }
  await client.connect();
  // client.doGetAddCode(client);
}
