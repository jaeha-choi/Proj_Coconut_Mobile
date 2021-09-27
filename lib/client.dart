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

class Client {
  String serverIP;
  int serverPort;
  late SecureSocket conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;
  late BytesBuilder dataBuilder;
  late StreamSubscription stream;
  Future<bool> isDataReady;

  Client({
    required String serverIP,
    required int serverPort,
    // SecureSocket? conn,
    required RSAPrivateKey privKey,
    required String pubKey,
    required String addCode,
    required Future<bool> isDataReady,
    // StreamSubscription? stream,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        // this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode,
        this.isDataReady = isDataReady;
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
      isDataReady: Future<bool>(() {
        return false;
      }),
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

    logger.i(
        'Connection from ${client.conn.remoteAddress.address}:${client.conn.remotePort}');

    final bytesBuilder = BytesBuilder();
    client.dataBuilder = BytesBuilder();

    client.stream = client.conn.listen(
      // handle data from the client
      (Uint8List data) async {
        client.isDataReady = onDataHelper(data, bytesBuilder, client);
      },
      //     onDone: () {
      //   client.stream.cancel();
      // }
    );

    // Initializing client
    await doInit(client);

    return true;
  } catch (e) {
    logger.e('Error in connect() :$e');
  }
  return false;
}

Future<bool> onDataHelper(
    Uint8List data, BytesBuilder bytesBuilder, Client client) async {
  if (bytesBuilder.length + data.length >= 5) {
    int offset = 5 - bytesBuilder.length;

    bytesBuilder.add(data.take(offset).toList());

    Uint8List byte = bytesBuilder.toBytes();
    int size = _readSize(byte); // 0
    logger.d("BytesBuilder Content: " +
        bytesBuilder.toBytes().toString() +
        "Received data: $data\nOffset: $offset\nOffset byte : " +
        data.take(offset).toString() +
        "\nSize $size");
    //TODO replace errCode with actual errCode
    int errCode = 0;
    if (data.length >= size) {
      bytesBuilder.clear();
      // print(offset);
      // print(size);
      var outputData;
      outputData = data.getRange(offset, size + offset).toList();
      logger.d("data: " + outputData.toString());
      client.dataBuilder.add(outputData);
      client.stream.pause();
      return true;
      //TODO return ErrorCode as well
      //TODO if there are remaining data, make sure to return the remaining item
      // onDataHelper(data.getRange(size, data.length).toList(), bytesBuilder);
    } else {
      bytesBuilder.add(data.getRange(offset, data.length).toList());
    }
  } else {
    bytesBuilder.add(data);
  }
  logger.d("-------------");
  return false;
}

/// Send initialization code to the server
Future<void> doInit(Client client) async {
  Uint8List pubKeyHash = PemToSha256(client.pubKeyBlock);
  // Send pubKeyHash to the server
  writeBytes(client.conn, pubKeyHash);
  getResult(client);
  return;
}

Future<bool> doGetAddCode(Client client) async {
  // Send the command to the server
  try {
    writeString(client.conn, command(GetAddCode));
    logger.i("writeString command (DoGetcode()) is done");
    await readBytes(client);
    return true;
  } catch (e) {
    logger.e("Error in doGetAddCode: $e");
  }
  return false;
}

/// Returns error code from the server
Future<void> getResult(Client client) async {
  // TODO: Get uint8 error code from the server
  readBytes(client);
  return;
}

// return the size of data
int _readSize(Uint8List data) {
  try {
    return bytesToUint32(data);
  } catch (e) {
    logger.e  ("Error in findSize(): $e");
  }
  return -1;
}

Future waitWhile(bool test(), [Duration pollInterval = Duration.zero]) {
  var completer = new Completer();
  check() {
    if (test()) {
      completer.complete();
    } else {
      new Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}

Future<Uint8List?> readBytes(Client client) async {
  try {
    // TODO: Finish implementing readBytes
    await waitWhile(() => client.stream.isPaused);

    // print(await client.isDataReady);

    var data = client.dataBuilder.takeBytes();
    print("Data: $data");
    client.stream.resume();

    return data;
  } catch (e) {
    logger.e("Error in readBytes: $e");
  }
  return null;
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
    _writeErrorCode(writer);
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
    writer.add(size);
  } catch (e) {
    logger.e("Error in writeSize() :$e");
  }
}

bool _writeErrorCode(SecureSocket writer) {
  try {
    // Write 1 byte of error code
    Uint8List code = Uint8List(1);
    writer.add(code);
    return true;
  } catch (e) {
    logger.e('Error in writeErrorCode() :$e');
  }
  return false;
}

Future<void> main() async {
  Logger.level = Level.info;
  Client? client = await newClient();
  if (client == null) {
    // TODO: Error handling
    return;
  }
  await connect(client);
  doGetAddCode(client);
}
