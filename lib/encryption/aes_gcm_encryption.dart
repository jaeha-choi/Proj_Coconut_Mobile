import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import "package:pointycastle/export.dart";
import 'package:basic_utils/basic_utils.dart';
import 'package:mobile_app/encryption/rsa.dart';
import 'package:chunked_stream/chunked_stream.dart';

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

/// ChunkSize is a size of each file chunks in bytes.
/// Should be less than max value of uint32 (4294967295)
///	since the util package use unsigned 4 byts to represent the data size.
const chunkSize = 16777216; // 2^24 bytes, about 16.7 MB
const IvSize = 12;
const SymKeySize = 32;

class EncryptedData {
  Uint8List encryptedData;
  Uint8List iv;

  EncryptedData({
    required encryptedData,
    required iv,
  })
      : encryptedData = encryptedData,
        iv= iv;
}

class AesGcmChunk {
  Uint8List key;
  File file;
  String fileName;

  // readOffSet is uInt64 check
  int readOffSet;

  // readChunkNum is uInt16 check
  int readChunkNum;

  // writeOffset is uInt64
  int writeOffset;

  // writeChunkNum is uInt64
  int writeChunkNum;

  // fileSize is uInt64 check
  int fileSize;

  // chunkCount is uInt16
  int chunkCount;

  AesGcmChunk({
    required key,
    required file,
    required fileName,
    required readOffSet,
    required fileSize,
    required chunkCount,
    required readChunkNum,
    required writeOffset,
    required writeChunkNum,
  })
      : this.key = key,
        this.fileName = fileName,
        this.file = file,
        this.fileSize = fileSize,
        this.chunkCount = chunkCount,
        this.readOffSet = readOffSet,
        this.readChunkNum = readChunkNum,
        this.writeOffset = writeOffset,
        this.writeChunkNum = writeChunkNum;
}

// it works like encryptBytes
/// Encrypts plain and return encrypted data
EncryptedData aesGcmEncrypt(Uint8List key, int ivSize, Uint8List paddedPlaintext) {
  // Create a GCM block cipher with AES, and initialize with key and IV

  // var rnd = SecureRandom('Fortuna');
  // Uint8List iv = rnd.nextBytes(ivSize);
  // print(iv);
  final _sGen = Random.secure();
  final _seed =
  Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
  final secRnd = SecureRandom("Fortuna")..seed(KeyParameter(_seed));

  final iv = secRnd.nextBytes(ivSize);
  final gcm = GCMBlockCipher(AESFastEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

  // Encrypt the plaintext block-by-block
  final cipherText = Uint8List(paddedPlaintext.length); // allocate space

  int offset = 0;
  while (offset < paddedPlaintext.length) {
    offset += gcm.processBlock(paddedPlaintext, offset, cipherText, offset);
    // offset += gcm.processBytes(inp, inpOff, len, out, outOff);
  }
  // does iv size matter? is it one byte good enough
  assert(offset == paddedPlaintext.length);
  Uint8List output= Uint8List(26);

  // authentication
  gcm.doFinal(output, offset);
  // Encrypted data
  return EncryptedData(encryptedData: output, iv: iv);
}


Uint8List aesGcmDecrypt(Uint8List key, Uint8List iv, Uint8List cipherText){
  final gcm = GCMBlockCipher(AESFastEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt
  // Decrypt the cipherText block-by-block
  final paddedPlainText = Uint8List(cipherText.length); // allocate space

  var offset = 0;
  while (offset < cipherText.length) {
    offset += gcm.processBlock(cipherText, offset, paddedPlainText, offset);
  }
  assert(offset == cipherText.length);

  Uint8List output = Uint8List(10);
  gcm.doFinal(output, 0);

  return output;
}
/// encryptSetup opens file using[filePath], determine number of chunks, and return
/// [fileName] is the name of the actual file
Future<AesGcmChunk> encryptSetup(String filePath, String fileName) async {
  // Generate symmetric encryption key
  Uint8List key = genAESSymKey();

  // Open src file for encryption
  File myFile = File(filePath);
  if (myFile == null) {
    logger.d('Error while opening a file');
  }

  // Get size of source file
  int fileSize = await myFile.length();
  if (fileSize == null) {
    logger.d("Error while getting file size");
  }

  // Get number of chunks (3/2 = 1)
  int chunkNum = (fileSize / chunkSize).toInt(); // TODO use Ceil??

  return AesGcmChunk(
      key: key,
      file: myFile,
      fileName: fileName,
      readOffSet: 0,
      readChunkNum: 0,
      writeOffset: 0,
      writeChunkNum: 0,
      fileSize: fileSize,
      chunkCount: chunkNum);
}

final Random _random = Random.secure();

Uint8List genAESSymKey([int length = 32]) {
  var values = List<int>.generate(length, (i) => _random.nextInt(256));
  Uint8List res = Uint8List.fromList(values);
  // return base64Url.encode(values); ??
  return res;
}

// convert uint16 to bytes
// TODO move to util.dart
Uint8List uint16ToBytes(int value) =>
    Uint8List(2)
      ..buffer.asByteData().setUint16(0, value, Endian.big);

/// Encrypts file and write to writer
/// Receiver's pub key is required for encrypting symmetric encryption key
/// Sender's private key is required for singing the encrypted key
Future<void> RSAEncrypt(AesGcmChunk ag, SecureSocket writer,
    String receiverPubKey,
    RSAPrivateKey senderPrivateKey) async {
  final BytesBuilder keyChNum = BytesBuilder();
  keyChNum.add(ag.key);
  keyChNum.add(uint16ToBytes(ag.chunkCount));

  // Encrypt and sign symmetric encryption key
  // TODO append RSAPublicKey on client
  RSAPublicKey pubKey = CryptoUtils.rsaPublicKeyFromPem(receiverPubKey);

  List? encryptSignData =
  rsaEncrypt(keyChNum.takeBytes(), pubKey, senderPrivateKey);
  Uint8List dataEncrypted = encryptSignData!.first;
  Uint8List dataSignature = encryptSignData.last;
  if (dataEncrypted == null) {
    logger.d("Error in RSAEncrypt while encrypt data returns null");
  }

  // Send encrypted symmetric key
  try {
    writeBytes(writer, dataEncrypted);
  } catch (e) {
    logger.d("Error in writeBytes while sending data encrypted");
  }

  // Send encrypted symmetric key signature
  try {
    writeBytes(writer, dataSignature);
  } catch (e) {
    logger.d("Error in writeBytes while sending data signature");
  }

  // Encrypt File name
  // List<int> froo = utf8.encode(ag.fileName);
  // Uint8List foo = Uint8List.fromList(froo);
  print('Byte(fileName): ${Uint8List.fromList(utf8.encode(ag.fileName))}');
  // generate iv creating 12 bytes of rand num crpyto.rand.safe.byte

  // TODO check it again
  EncryptedData encryptedData = aesGcmEncrypt(
      ag.key, IvSize, Uint8List.fromList(utf8.encode(ag.fileName)));

  // Send IV (Nonce)
  writeBytes(writer, encryptedData.iv);

  // Send encrypted file name
  writeBytes(writer, encryptedData.encryptedData);

  // Send encrypted file
  // List encryptedFileChunk;

  EncryptedData encryptedFileChunk;
  // Loop until every byte is sent
  // ag.readOffset and ag.readChunkNum are updated in encryptedChunk
  while (ag.readOffSet < ag.fileSize) {
    if (ag.readOffSet + chunkSize >= ag.fileSize) {
      // Send last chunk
      encryptedFileChunk = await encryptChunk(ag.fileSize - ag.readOffSet, ag);
    } else {
      // Send Chunk
      encryptedFileChunk = await encryptChunk(chunkSize, ag);
    }
    // send IV in plain text
    writeBytes(writer, encryptedFileChunk.iv);

    // Send encrypted file chunk + current chunk number (first two bytes)
    writeBytes(writer, encryptedFileChunk.encryptedData);
  }
}

/// Encrypts portion of the file and return it as []byte with current chunk number
/// appended in the beginning (first two bytes). IV is also returned in plain text
/// possible alternative way https://stackoverflow.com/questions/61767561/read-specific-chunk-of-bytes-in-flutter-dart
Future<EncryptedData> encryptChunk(int chunkSize, AesGcmChunk ag) async {
  // Read chunk of file to encrypt
  // First approach using BytesBuilder
    BytesBuilder plain = BytesBuilder();
    // Uint8List fileInfo = ag.file.readAsBytesSync();

    // Second approach using Chunk Stream util
    final reader = ChunkedStreamIterator(ag.file.openRead());
    List<int> data = await reader.read(chunkSize); // null safety

    // get Current chunk number
    Uint8List currentChunkNum = uint16ToBytes(ag.readChunkNum);

    // Plain data is combined with current chunk number to be sent
    plain.add(currentChunkNum);
    plain.add(data);

    // Encrypt chunk of file and return encrypted output, IV, and error, if any.
    // var rnd = FortunaRandom();
    // Uint8List iv = rnd.nextBytes(IvSize);
    EncryptedData encryptedData = aesGcmEncrypt(ag.key, IvSize, plain.toBytes());

    // Update variables for loop in Encrypt
    ag.readChunkNum += 1;
    ag.readOffSet += plain.length - currentChunkNum.length;
    return encryptedData;

}

// /// encryptBytes encrypts plain and return encrypted data, IV that was used
// void encryptedBytes(BytesBuilder plain){
//
// }


void main() {
   String str = "Hello Guri";
   List<int> byte = utf8.encode(str);
   Uint8List plain = Uint8List.fromList(byte);
   print("plain message in byte: $plain");

   // generating AES
   Uint8List key = genAESSymKey();
   // print("AES KEY: $key");

   // encrypt
  EncryptedData encryptedData = aesGcmEncrypt(key, IvSize, plain);
  print(encryptedData.encryptedData);

  print(aesGcmDecrypt(key, encryptedData.iv, encryptedData.encryptedData));
  // print(encryptedData.iv);


}