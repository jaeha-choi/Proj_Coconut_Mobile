import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:core';
import 'logger.dart';
import 'package:pointycastle/api.dart';
import 'package:basic_utils/basic_utils.dart';
import 'commands.dart';

final logger = Logger(printer: SimpleLogPrinter('client.dart'));


class Client {
  //TODO add tlsConfig?
  String serverIP; //TODO yaml?
  int serverPort; //TODO yaml?
  RawSecureSocket conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;

  Client({
    String serverIP,
    int serverPort,
    RawSecureSocket conn,
    RSAPrivateKey privKey,
    String pubKey,
    String addCode,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        this.conn = conn,
        this.privKey = privKey,
        this.pubKeyBlock = pubKey,
        this.addCode = addCode;
}

String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  var topLevel = new ASN1Sequence();
  topLevel.add(ASN1Integer(publicKey.modulus));
  topLevel.add(ASN1Integer(publicKey.exponent));
  var dataBase64 = base64.encode(topLevel.encodedBytes);
  return """-----BEGIN RSA PUBLIC KEY-----\r\n$dataBase64\r\n-----END RSA PUBLIC KEY-----""";
}

// pem -> key is decode
// key -> pem is encode
Future<Client> newClient() async {
  // Open RSA keys, if the user already got one
  bool ifPubFileExist = File('key.pub').existsSync();
  bool ifPrivFileExist = File('key.priv').existsSync();
  String pubKey = '';
  try {
    if (ifPubFileExist == true && ifPrivFileExist == true) {
      // Use existing pem file
      pubKey = File('key.pub').readAsStringSync();
    }
    // Create pem file
    else {
      await createPemFile();
      pubKey = File('key.pub').readAsStringSync();
    }

    // Decode Private key from PEM Format
    RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(
        File('key.priv').readAsStringSync());

    Client client = new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      conn: null,
      privKey: privateKey,
      pubKey: pubKey,
    );
    return client;
  } catch (e) {
    logger.d("ERROR in Client newClient(): $e");
  }
}

/// Creates [RSAPublicKey] & [RSAPrivateKey] and save them locally
Future<void> createPemFile() async {
  // RSAKeyGenerator keyGen = ...
  try {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: 4096);
    // exampleSecureRandom()); // produces an AsymmetricKeyPair

    // Examine the generated key-pair
    final rsaPublic = pair.publicKey as RSAPublicKey;
    final rsaPrivate = pair.privateKey as RSAPrivateKey;
    // print(encodePublicKeyToPemPKCS1(rsaPublic));
    // print(encodePrivateKeyToPemPKCS1(rsaPrivate))
    await File('key.priv')
        //   encodeRSAPrivateKeyToPem is a static method, thus you need to call class name
        .writeAsString(CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(rsaPrivate));
    await File('key.pub')
        .writeAsString(CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic));
  } catch (e) {
    logger.d('Error in createPemFile() $e');
  }
}

/// connects to a socket with TLS
void connect(Client client) async {
  // client = newClient() as Client;
  try {
    logger.d('Connecting....');
    // ConnectionTask dial1; <= TODO Return type?
    ConnectionTask<RawSecureSocket> connection;
    connection = await RawSecureSocket.startConnect(
      client.serverIP,
      client.serverPort,
      onBadCertificate: (certificate) => true,
    );
    // Socket con = await connection.socket;
    client.conn = await connection.socket;
    logger.i(client.conn);
    // Initializing client
    doInit(client);
  } catch (e) {
    logger.d('Error in connect() :$e');
  }
}

void doInit(Client client) {
  Uint8List pubKeyHash = PemToSha256(client.pubKeyBlock);
  // Send pubKeyHash to the server
  writeBytes(client.conn, pubKeyHash);

  return getResult(client.conn);
  // return getResult()
}

void getResult(RawSecureSocket conn) {
  return readBytes(conn);
}
/// PemToSHA256
/// Given pubKey [String] convert it to SHA256
/// [Uint8List]
Uint8List PemToSha256(String pubKey) {
  // Convert string to byte
  var byte = Uint8List.fromList(pubKey.codeUnits);

  // * actual information converted into byte
  // sha256sum always returns 32 bytes
  var sha256 = Digest("SHA-256").process(byte);
  return sha256;
}

/// WriteString writes message to writer TODO move to util.dart
/// length of message cannot exceed BufferSize
/// returns [total bytes sent, error]
Uint8List writeBytes(RawSecureSocket writer, Uint8List bytes) {
  try {
    // Convert string to byte
    // Get size(uint32) of total bytes to send
    var size = uint32ToByte(bytes.length);
    // logger.d(bytes.length);
    // logger.d(size);
    // logger.d(utf8.encode(size.toString()));

    // Write size[uint8] of the file to writer
    writeSize(writer, size);
    // Write error code
    writeErrorCode(writer);
    // Write file to writer
    writer.write(bytes);

    return bytes;
  } catch (error) {
    logger.d('Error in writeString() :$error');
    return Uint8List(1);
  }
}

/// TODO move to util.dart
/// Given a socket [Socket] and size of the file [Uint8List]
void writeSize(RawSecureSocket writer, Uint8List size) {
  try {
    // Write size of the string to writer
    writer.write(size);
  } catch (e) {
    logger.d("Error in writeSize() :$e");
  }
}

/// TODO move to util.dart
void writeErrorCode(RawSecureSocket writer) {
  Uint8List code = Uint8List(1); // code = [0]  NOTE: [255] = [1,1,1,1,1,1,1,1] = 8 bits = 1 byte
  // print(code);
  // Write 1 byte of error code
  try {
    writer.write(code);
  } catch (e) {
    logger.d('Error in writeErrorCode() :$e');
  }
}

// TODO move to util.dart
// Unsigned int32 to byte
Uint8List uint32ToByte(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

// void getResult(RawSecureSocket conn) {
//   readBytes(conn);
// }

// TODO move to util.dart
void readBytes(RawSecureSocket reader) {
  // Read packet size
  int size = readSize(reader);
  logger.i(size);

  // Read Error Code
  readErrorCode(reader);

  // Read bytes from reader
  readNBytes(reader, size);
}

int readErrorCode(RawSecureSocket reader) {
  // Read 1 byte for the error code
  Uint8List b = readNBytes(reader, 4);

  // if there is no error
  if (b  !=Uint8List(1)) {
    logger.d("There is no reading error code");
    //TODO need to implement more
    int readError = 0;
    return readError;
  }
}

Uint32List intToUint32(int value) {
  var buffer = value;

}

// Byte to unsigned int32
int byteToUint32(Uint8List value) {
  var buffer = value.buffer;
  var byteData = new ByteData.view(buffer);
  return byteData.getUint32(0);
}

// TODO move to util
int readSize(RawSecureSocket reader) {
  try {
    // Read first 4 bytes for the size
    Uint8List byte = readNBytes(reader, 4);
    // convert byte to Uint32
    // Uint32List res = byte.buffer.asUint32List();
    int size = byteToUint32(byte);
    logger.i("Size: " + size.toString());
    return size;
  }catch(e){
    logger.d("Error in readSize(): $e");
  }
}

// convert Uint32 to Integer Im not too sure about this method
int Uint32ToInt(Uint32List value) {
  var buffer = value.buffer;
  var byteData = new ByteData.view(buffer);
  return byteData.getInt64(0);
}
//
// Future<List<int>> read(Socket reader, int numBytes){
//   var buffer = Uint8List(4);
// }

/// readNBytes reads up to nth byte
///  TODO move to util and change [int] parameter to [Uint32List]
/// return data(8-bit unsigned integers)
Uint8List readNBytes(RawSecureSocket reader, int n) {
  try {
    Uint8List buffer = reader.read(n);
    logger.i(buffer.length);
    return buffer;
  } catch(e) {
    logger.d("Error in readNBytes() :$e");
  }
}


// print(String.fromCharCode(data));
// new String.fromCharCode(charCode)
// if (packetData == null) {
//   print("Error while reading bytes");
//   return null;
// }
// return packetData;

void doGetAddCode(Client client) {
  // Send the command to the server
  try {
    writeString(client.conn, command(GetAddCode));
    logger.i("writeString = get code is done");
    readBytes(client.conn);
  } catch (e) {
    logger.d("Error in doGetAddCode: $e");
  }
}

// TODO move to Util
void writeString(RawSecureSocket writer, String msg) {
  try{
    Uint8List bytes = utf8.encode(msg);
    writeBytes(writer, bytes);
  } catch(e) {
    logger.d("Error in writeString(): $e");
  }

}

Future<void> main() async {
  Logger.level = Level.debug;
  Client client = await newClient();
  await connect(client);
  print(client.conn);
  doGetAddCode(client);
}
