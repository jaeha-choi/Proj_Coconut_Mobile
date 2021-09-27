import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';

const int rsaKeySize = 4096;
const int bufferSize = 4096;

var logger = Logger(
  printer: PrettyPrinter(
      methodCount: 1,
      // number of method calls to be displayed
      errorMethodCount: 3,
      // number of method calls if stacktrace is provided
      lineLength: 50,
      // width of the output
      colors: true,
      // Colorful log messages
      printEmojis: true,
      // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
      ),
);

/// ----Conversions----

/// Convert 4 bytes to unsigned int32
int bytesToUint32(Uint8List value, [int offsetInBytes = 0]) {
  // var buffer = value.buffer;
  // var byteData = new ByteData.view(buffer, offsetInBytes, 4);
  ByteData byteData =
      ByteData.sublistView(value, offsetInBytes, offsetInBytes + 4);
  return byteData.getUint32(0);
}

/// Convert unsigned int32 to bytes
Uint8List uint32ToBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

/// ----RSA Related----

/// Convert [publicKey] to PEM format string
String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  var topLevel = new ASN1Sequence();
  topLevel.add(ASN1Integer(publicKey.modulus));
  topLevel.add(ASN1Integer(publicKey.exponent));
  var dataBase64 = base64.encode(topLevel.encodedBytes!);
  return "-----BEGIN RSA PUBLIC KEY-----\r\n$dataBase64\r\n-----END RSA PUBLIC KEY-----";
}

/// Creates [RSAPublicKey] & [RSAPrivateKey] and save them locally.
/// Returns true if PEM files are created, false otherwise.
Future<bool> createPemFile() async {
  try {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: rsaKeySize);

    // Examine the generated key-pair
    final rsaPublic = pair.publicKey as RSAPublicKey;
    final rsaPrivate = pair.privateKey as RSAPrivateKey;

    File('key.priv').writeAsStringSync(
        CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(rsaPrivate));
    File('key.pub')
        .writeAsStringSync(CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic));

    return true;
  } catch (e) {
    logger.e('Error in createPemFile() $e');
  }
  return false;
}

/// Convert PEM formatted string [pubKey] to SHA256 bytes
Uint8List PemToSha256(String pubKey) {
  // Convert string to byte
  var byte = Uint8List.fromList(pubKey.codeUnits);
  return Digest("SHA-256").process(byte);
}

// WriteString writes message to writer
// length of message cannot exceed BufferSize
// returns <total bytes sent, error>
List writeString(RawSocket writer, String msg) {
  try {
    // Convert string to byte
    // * actual information converted into byte
    var bytes = utf8.encode(msg);
    // Get size(uint32) of total bytes to send
    var size = uint32ToBytes(bytes.length);
    writer.write(size + bytes);
    return [size, true];
  } catch (error) {
    return [0, false];
  }
}

// // getFilePath calls getApplication Documents Directory. This comes from the path_provider package.
// // This will get whatever the common documents directory is for the platform that we are using.
// // returns path to the documents directory as a String
// Future<String> getFilePath() async {
//   Directory appDocumentsDirectory = await getApplicationDocumentsDirectory(); // 1
//   String appDocumentsPath = appDocumentsDirectory.path; // 2
//   String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3
//
//   return filePath;
// }

// writeBinary opens file and write byte data to writer
//
// returns <total length of bytes to sent, error>
// total length of bytes = each file size
// file size cannot exceed max value of uint32
Future<List> writeBinary(RawSocket conn, File file) async {
  var sizeInByte = uint32ToBytes(await file.length());
  try {
    conn.write(sizeInByte);
    print(file.readAsBytes());
    print("reading file size (Bytes):  ${file.readAsBytes()}");
    conn.write(await file.readAsBytes());
  } catch (error) {
    logger.e("Unknown error in send_bin: $error");
    return [0, false];
  }
  return [sizeInByte, true];
}

@deprecated
void connects_to_socket() async {
  try {
    RawSocket socket = await RawSocket.connect('143.198.234.58', 1234);
    print(socket);
  } on SocketException catch (e) {
    print(e);
  }
}
