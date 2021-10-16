import 'dart:async';
import 'dart:convert';
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
  late StreamIterator connDataIterator;

  Client({
    required String serverIP,
    required int serverPort,
    // SecureSocket? conn,
    required RSAPrivateKey privKey,
    required String pubKey,
    required String addCode,
    // StreamSubscription? stream,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        // this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode;

// this.stream = stream;

  /// Connects to the server
  /// Returns true if connected to the server, false otherwise.
  Future<Error> connect(Client client) async {
    try {
      logger.i('Connecting....');
      client.conn = await SecureSocket.connect(
        client.serverIP,
        client.serverPort,
        onBadCertificate: (certificate) => true,
      );

      client.connDataIterator = StreamIterator(client.conn);

      logger.i(
          'Connected to ${client.conn.remoteAddress.address}:${client.conn.remotePort}');
    } catch (e) {
      logger.e('Error in connect() :$e');
    }
    // Initializing client
    return await doInit(client);
  }

  /// Send initialization code to the server
  Future<Error> doInit(Client client) async {
    Uint8List pubKeyHash = pemToSha256(client.pubKeyBlock);
    // Send pubKeyHash to the server
    if (writeBytes(client.conn, pubKeyHash) == -1) {
      logger.d("Error in doInit()");
    }
    return await getResult(client);
  }

  /// Returns error code from the server
  Future<Error> getResult(Client client) async {
    Message msg = await readBytes(client.connDataIterator);
    // msg.data;
    return msg.errorCode;
  }

  /// Remove Add Code
  Future<void> doRemoveAddCode(Client client) async {
    try {
      // Send the remove add code command
      int err = writeString(client.conn, command(RemoveAddCode));
      if (err == -1) {
        logger.d("Error while sending command(Remove Add Code) to the server");
      }
      // send the add code that you want to erase
      int err2 = writeString(client.conn, client.addCode);
      if (err2 == -1) {
        logger.d("Error while sending free add code to the server");
      }

      // Erase add code front client
      client.addCode = '';

      await getResult(client);
    } catch (e) {
      logger.e("Error in doRemoveAddCode: $e");
    }
  }

  /// Sends command(Get Add Code)
  Future<void> doGetAddCode(Client client) async {
    // Send the command to the server
    try {
      writeString(client.conn, command(GetAddCode));
      logger.i("writeString command (DoGetcode()) is done");
      Message msg = await readBytes(client.connDataIterator);
      logger.i("Add Code: ${utf8.decode(msg.data)}");
      client.addCode = utf8.decode(msg.data);
      await getResult(client);
      // return utf8.decode(msg.data);
      // return true;
    } catch (e) {
      logger.e("Error in doGetAddCode: $e");
      // return false;
    }
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
    serverIP: "147.182.243.190",
    serverPort: 9129,
    // conn: null,
    privKey: privateKey,
    pubKey: pubKey,
    addCode: "",
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
  await client.connect(client);
  await client.doGetAddCode(client);
  return client;
}

Future<void> main() async {
  Logger.level = Level.debug;
  Client? client = await newClient();
  if (client == null) {
    // TODO: Error handling
    return;
  }
  await client.connect(client);
  client.doGetAddCode(client);
}
