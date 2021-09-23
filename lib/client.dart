import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/util.dart';

import 'commands.dart';

final logger = Logger(
  printer: PrettyPrinter(
      // number of method calls to be displayed
      methodCount: 1,
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
  RawSecureSocket? conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;

  Client({
    required String serverIP,
    required int serverPort,
    RawSecureSocket? conn,
    required RSAPrivateKey privKey,
    required String pubKey,
    required String addCode,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode;
}

/// Creates new [Client] and return it.
/// Returns null upon error.
Future<Client?> newClient() async {
  try {
    // Open RSA keys, if the user already got one
    bool isPub = File('key.pub').existsSync();
    bool isPriv = File('key.priv').existsSync();

    // If at least one key is not found, create new key pairs
    if (!(isPub && isPriv)) {
      await createPemFile();
    }

    // Public key needs to be in a string format
    String pubKey = File('key.pub').readAsStringSync();
    // Private key needs to be in a PEM format
    RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(
        File('key.priv').readAsStringSync());

    return new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      conn: null,
      privKey: privateKey,
      pubKey: pubKey,
      addCode: "",
    );
  } catch (e) {
    logger.e('Error in newClient() $e');
  }
  return null;
}

/// Connects to the server
/// Returns true if connected to the server, false otherwise.
Future<bool> connect(Client client) async {
  try {
    logger.i('Connecting....');
    ConnectionTask<RawSecureSocket> connection =
        await RawSecureSocket.startConnect(
      client.serverIP,
      client.serverPort,
      onBadCertificate: (certificate) => true,
    );
    client.conn = await connection.socket;

    // Initializing client
    doInit(client);

    return true;
  } catch (e) {
    logger.e('Error in connect() :$e');
  }
  return false;
}

/// Send initialization code to the server
void doInit(Client client) {
  Uint8List pubKeyHash = PemToSha256(client.pubKeyBlock);
  // Send pubKeyHash to the server
  writeBytes(client.conn!, pubKeyHash);

  return getResult(client.conn!);
}

Future<bool> doGetAddCode(Client client) async {
  // Send the command to the server
  try {
    writeString(client.conn!, command(GetAddCode));
    logger.i("writeString command (DoGetcode()) is done");
    readBytes(client.conn!);
    return true;
  } catch (e) {
    logger.e("Error in doGetAddCode: $e");
  }
  return false;
}

/// Returns error code from the server
void getResult(RawSecureSocket conn) {
  // TODO: Get uint8 error code from the server
  readBytes(conn);
  return;
}

Future<Uint8List?> readBytes(RawSecureSocket conn) async {
  try{
    // TODO: Finish implementing readBytes
    Uint8List result = ;
    return result;
  }catch (e) {
    logger.e("Error in readBytes: $e");
  }
  return null;
}

bool writeString(RawSecureSocket writer, String msg) {
  if (msg.isEmpty) {
    logger.e("msg cannot be empty");
    return false;
  }
  try {
    Uint8List? bytes = utf8.encode(msg) as Uint8List?;
    if (bytes == null) {
      throw Exception("bytes cannot be null");
    }
    writeBytes(writer, bytes);
    return true;
  } catch (e) {
    logger.e("Error in writeString(): $e");
  }
  return false;
}

/// WriteString writes message to writer
/// length of message cannot exceed BufferSize
/// returns [total bytes sent]
Uint8List writeBytes(RawSecureSocket writer, Uint8List bytes) {
  try {
    // Convert string to byte
    // Get size(uint32) of total bytes to send
    var size = uint32ToBytes(bytes.length);
    // logger.d(bytes.length);
    // logger.d(size);
    // logger.d(utf8.encode(size.toString()));

    // Write size[uint8] of the file to writer
    _writeSize(writer, size);
    // Write error code
    _writeErrorCode(writer);
    // Write file to writer
    writer.write(bytes);

    return bytes;
  } catch (error) {
    logger.e('Error in writeString() :$error');
    return Uint8List(1);
  }
}

/// Given a socket [Socket] and size of the file [Uint8List]
void _writeSize(RawSecureSocket writer, Uint8List size) {
  try {
    // Write size of the string to writer
    writer.write(size);
  } catch (e) {
    logger.e("Error in writeSize() :$e");
  }
}

bool _writeErrorCode(RawSecureSocket writer) {
  try {
    // Write 1 byte of error code
    Uint8List code = Uint8List(1);
    writer.write(code);
    return true;
  } catch (e) {
    logger.e('Error in writeErrorCode() :$e');
  }
  return false;
}

Future<void> main() async {
  Logger.level = Level.debug;
  Client? client = await newClient();
  if (client == null) {
    // TODO: Error handling
    return;
  }
  await connect(client);

  // doGetAddCode(client);
}
