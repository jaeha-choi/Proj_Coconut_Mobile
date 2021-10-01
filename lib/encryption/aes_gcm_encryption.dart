import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import "package:pointycastle/export.dart";
import 'package:basic_utils/basic_utils.dart';
import 'package:mobile_app/util.dart';
import 'package:mobile_app/encryption/rsa.dart';

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

class AesGcmChunk {
  Uint8List key;
  File file;
  String fileName;
  Uint64List readOffSet;

  // Uint16List readChunkNum;
  // Uint16List writeOffset;
  // Uint16List writeChunkNum;
  Uint64List fileSize;
  Uint16List chunkCount;

  AesGcmChunk({
    required key,
    required file,
    required fileName,
    required readOffSet,
    required fileSize,
    required chunkCount,
  })  : this.key = key,
        this.fileName = fileName,
        this.file = file,
        this.fileSize = fileSize,
        this.chunkCount = chunkCount,
        this.readOffSet = readOffSet;
}

/// ChunkSize is a size of each file chunks in bytes.
/// Should be less than max value of uint32 (4294967295)
///	since the util package use unsigned 4 byts to represent the data size.
const chunkSize = 16777216; // 2^24 bytes, about 16.7 MB
const IvSize = 12;
const SymKeySize = 32;

Uint8List aesGcmEncrypt(
    Uint8List key, Uint8List iv, Uint8List paddedPlaintext) {
  // Create a GCM block cipher with AES, and initialize with key and IV

  final gcm = GCMBlockCipher(AESFastEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

  // Encrypt the plaintext block-by-block

  final cipherText = Uint8List(paddedPlaintext.length); // allocate space

  int offset = 0;
  while (offset < paddedPlaintext.length) {
    offset += gcm.processBlock(paddedPlaintext, offset, cipherText, offset);
  }
  assert(offset == paddedPlaintext.length);

  // Encrypted data
  return cipherText;
}

/// encryptSetup opens file using[filePath], determine number of chunks, and return
/// [fileName] is the name of the actual file
AesGcmChunk encryptSetup(String filePath, String fileName) {
  // Generate symmetric encryption key
  String key = genAESSymKey();

  // Open src file for encryption
  File myFile = File(filePath);
  if (myFile == null) {
    logger.d('Error while opening a file');
  }

  // Get size of source file
  int fileSize = myFile.lengthSync();
  if (fileSize == null) {
    logger.d("Error while getting file size");
  }

  // Get number of chunks
  int chunkNum = (fileSize / chunkSize).toInt();

  return AesGcmChunk(
      key: key,
      file: myFile,
      fileName: fileName,
      readOffSet: 0,
      fileSize: fileSize.toUnsigned(64),
      chunkCount: chunkNum.toUnsigned(16));
}

final Random _random = Random.secure();

String genAESSymKey([int length = 32]) {
  var values = List<int>.generate(length, (i) => _random.nextInt(256));

  return base64Url.encode(values);
}

/// Encrypts file and write to writer
/// Receiver's pub key is required for encrypting symmetric encryption key
/// Sender's private key is required for singing the encrypted key
void RSAEncrypt(AesGcmChunk ag, SecureSocket writer, String recieverPubKey,
    RSAPrivateKey senderPrivateKey) {
  final BytesBuilder keyChNum = BytesBuilder();
  keyChNum.add(uint16ToBytes(ag.chunkCount[0]));
  keyChNum.add(ag.key);

  // REncrypt and sign symmetric encryption key
  RSAPublicKey pubKey = CryptoUtils.rsaPublicKeyFromPem(recieverPubKey);
  List? encryptSignData = rsaEncrypt(keyChNum.takeBytes(), pubKey, senderPrivateKey);
  Uint8List encryptData = encryptSignData!.first;
  Uint8List dataSignature = encryptSignData!.last;
  if (encryptData == null){
    logger.d("Error in RSAEncrypt while encrypt data returns null");
  }

  // Send encrypted symmetric key
  try {
    writeBytes(writer, encryptData);
  } catch (e){
    logger.d("Error in writeBytes while sending data encrypted");
  }

  // Send encrypted symmetric key signature
  try{
    writeBytes(writer, dataSignature);
  } catch(e){
    logger.d("Error in writeBytes while sending data signature");
  }

  // Encrypt File name
  // List<int> froo = utf8.encode(ag.fileName);
  // Uint8List foo = Uint8List.fromList(froo);
  print(Uint8List.fromList(utf8.encode(ag.fileName));
      aesGcmEncrypt(ag.key, iv, Uint8List.fromList(utf8.encode(ag.fileName)));
}



