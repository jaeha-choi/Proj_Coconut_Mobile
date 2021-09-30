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
  int size;
  int errorCode;
  Uint8List data;

  Message({
    required int size,
    required int errorCode,
    required Uint8List data,
  })  : size = size,
        errorCode = errorCode,
        data = data;
}

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
      // conn: null,
      privKey: privateKey,
      pubKey: pubKey,
      addCode: "",
      // stream: null,
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
    client.conn = await SecureSocket.connect(
      client.serverIP,
      client.serverPort,
      onBadCertificate: (certificate) => true,
    );
    client.connDataIterator = StreamIterator(client.conn);

    logger.i(
        'Connected to ${client.conn.remoteAddress.address}:${client.conn.remotePort}');

    // Initializing client
    await doInit(client);

    return true;
  } catch (e) {
    logger.e('Error in connect() :$e');
  }
  return false;
}

/// Send initialization code to the server
Future<void> doInit(Client client) async {
  Uint8List pubKeyHash = PemToSha256(client.pubKeyBlock);
  // Send pubKeyHash to the server
  writeBytes(client.conn, pubKeyHash);
  await getResult(client);
  return;
}

Future<bool> doGetAddCode(Client client) async {
  // Send the command to the server
  try {
    writeString(client.conn, command(GetAddCode));
    logger.i("writeString command (DoGetcode()) is done");
    Message msg = await readBytes(client);
    logger.i("Add Code: ${utf8.decode(msg.data)}");
    await getResult(client);
    return true;
  } catch (e) {
    logger.e("Error in doGetAddCode: $e");
  }
  return false;
}

/// Returns error code from the server
Future<int> getResult(Client client) async {
  // TODO: Convert error code (int) to an Error object
  Message msg = await readBytes(client);
  return msg.errorCode;
}

Future<Message> readBytes(Client client) async {
  int size = -1;
  int errorCode = 255; // TODO: update to actual "unknown error" error code
  Uint8List data = Uint8List(0);

  try {
    // Wait for the size + error code
    bool isDataAvailable = await client.connDataIterator.moveNext();
    if (!isDataAvailable) {
      throw new Exception("no data available from the server");
    }
    Uint8List sizeErrorCode = client.connDataIterator.current;
    size = bytesToUint32(sizeErrorCode);
    errorCode = sizeErrorCode[4];

    // If the packets can be trimmed before received, check if the size of
    // received data matches the size of the original msg
    if (size != 0) {
      isDataAvailable = await client.connDataIterator.moveNext();
      if (!isDataAvailable) {
        throw new Exception("no data available from the server");
      }
      data = client.connDataIterator.current;
    }
  } catch (e) {
    logger.e("Error in readBytes: $e");
  }

  logger.i("readBytes\tSize:$size\tErrorCode:$errorCode\tData:$data");

  return Message(size: size, errorCode: errorCode, data: data);
}

bool writeString(SecureSocket writer, String msg) {
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
Uint8List writeBytes(SecureSocket writer, Uint8List bytes) {
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
    // _writeErrorCode(writer);
    // Write file to writer
    writer.add(bytes);

    return bytes;
  } catch (error) {
    logger.e('Error in writeString() :$error');
    return Uint8List(1);
  }
}

/// Given a socket [Socket] and size of the file [Uint8List]
void _writeSize(SecureSocket writer, Uint8List size) {
  try {
    // Write size of the string to writer
    // Write 1 byte of error code
    Uint8List code = Uint8List(1);

    writer.add(size +code);
  } catch (e) {
    logger.e("Error in writeSize() :$e");
  }
}

bool _writeErrorCode(SecureSocket writer) {
  try {
    // Write 1 byte of error code
    //TODO create errrorCode class
    Uint8List code = Uint8List(1);
    writer.add(code);
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
  doGetAddCode(client);
}
