import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/encryption/rsa.dart';
import "package:pointycastle/export.dart";

import '../util.dart';

final Random _random = Random.secure();

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

class _EncryptedData {
  Uint8List encryptedData;
  Uint8List iv;

  _EncryptedData({
    required encryptedData,
    required iv,
  })  : encryptedData = encryptedData,
        iv = iv;
}

class AesGcmChunk {
  Uint8List? key;
  File file;
  var stream;
  String fileName;

  // offset is uInt64 check
  int offset;

  // chunkNum is uInt16 check
  int chunkNum;

  // fileSize is uInt64 check
  int fileSize;

  // chunkCount is uInt16
  int chunkCount;

  AesGcmChunk._(this.key, this.stream, this.fileName, this.file, this.fileSize,
      this.chunkCount, this.offset, this.chunkNum);

  /// Encrypts file and write to writer
  /// Receiver's pub key is required for encrypting symmetric encryption key
  /// Sender's private key is required for singing the encrypted key
  Future<void> encrypt(SecureSocket writer, RSAPublicKey receiverPubKey,
      RSAPrivateKey senderPrivateKey) async {
    final BytesBuilder keyChNum = BytesBuilder();
    keyChNum.add(this.key!);
    keyChNum.add(uint16ToBytes(this.chunkCount));

    // Encrypt and sign symmetric encryption key
    List encryptSignData =
        encryptSignMsg(keyChNum.takeBytes(), receiverPubKey, senderPrivateKey);

    // Send encrypted symmetric key
    try {
      writeBytes(writer, encryptSignData.first);
    } catch (e) {
      logger.d("Error in writeBytes while sending data encrypted");
    }

    // Send encrypted symmetric key signature
    try {
      writeBytes(writer, encryptSignData.last);
    } catch (e) {
      logger.d("Error in writeBytes while sending data signature");
    }

    _EncryptedData encryptedData = _encryptBytes(
        Uint8List.fromList(utf8.encode(this.fileName)), this.key!);

    // Send IV (Nonce)
    writeBytes(writer, encryptedData.iv);

    // Send encrypted file name
    writeBytes(writer, encryptedData.encryptedData);

    // Send encrypted file
    // List encryptedFileChunk;

    _EncryptedData encryptedFileChunk;
    // Loop until every byte is sent
    // this.readOffset and this.readChunkNum are updated in encryptedChunk
    while (this.offset < this.fileSize) {
      if (this.offset + chunkSize >= this.fileSize) {
        // Send last chunk
        encryptedFileChunk = await _encryptChunk(this.fileSize - this.offset);
      } else {
        // Send Chunk
        encryptedFileChunk = await _encryptChunk(chunkSize);
      }
      // send IV in plain text
      writeBytes(writer, encryptedFileChunk.iv);

      // Send encrypted file chunk + current chunk number (first two bytes)
      writeBytes(writer, encryptedFileChunk.encryptedData);
    }
  }

  /// Encrypts portion of the file and return it as []byte with current chunk number
  /// appended in the beginning (first two bytes). IV is also returned in plain text
  Future<_EncryptedData> _encryptChunk(int chunkSize) async {
    // Read chunk of file to encrypt
    final BytesBuilder plain = BytesBuilder();

    List<int> data = await this.file.openRead(this.offset, chunkSize).single;

    // get Current chunk number
    Uint8List currentChunkNum = uint16ToBytes(this.chunkNum);

    // Plain data is combined with current chunk number to be sent
    plain.add(currentChunkNum);
    plain.add(data);

    // Encrypt chunk of file and return encrypted output, IV, and error, if any.
    _EncryptedData encryptedData = _encryptBytes(plain.takeBytes(), this.key!);

    // Update variables for loop in Encrypt
    this.chunkNum += 1;
    this.offset += plain.length;
    return encryptedData;
  }
}

/// encryptSetup opens file using[filePath], determine number of chunks, and return
/// [fileName] is a full path of a file. e.g. /foo/bar/cat.jpg
AesGcmChunk encryptSetup(String filename) {
  final File f = File(filename);
  final size = f.lengthSync();
  return AesGcmChunk._(
      _genAESSymKey(), null, filename, f, size, size ~/ chunkSize, 0, 0);
}

///decryptSetup creates temporary file, make directory if it doesn't exist then return *AesGcmChunk
AesGcmChunk decryptSetup() {
  // TODO: add download path
  final File f = File("temp");
  return AesGcmChunk._(null, f.openWrite(), "", f, 0, 0, 0, 0);
}

/// Encrypts plain and return encrypted data, IV that was used as [_EncryptedData]
_EncryptedData _encryptBytes(Uint8List paddedPlaintext, Uint8List key) {
  final _seed =
      Uint8List.fromList(List.generate(32, (n) => _random.nextInt(255)));
  final secRnd = SecureRandom("Fortuna")..seed(KeyParameter(_seed));

  final iv = secRnd.nextBytes(IvSize);
  final gcm = GCMBlockCipher(AESFastEngine())
    ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

  return _EncryptedData(encryptedData: gcm.process(paddedPlaintext), iv: iv);
}

/// Decrypts encrypted data with IV and key
Uint8List _decryptBytes(_EncryptedData data, Uint8List key) {
  final gcm = GCMBlockCipher(AESFastEngine())
    ..init(
        false, AEADParameters(KeyParameter(key), 128, data.iv, Uint8List(0)));
  return gcm.process(data.encryptedData);
}

Uint8List _genAESSymKey([int length = 32]) {
  var values = List<int>.generate(length, (i) => _random.nextInt(256));
  Uint8List res = Uint8List.fromList(values);
  // return base64Url.encode(values); ??
  return res;
}

Future<void> main() async {
  String str = "Hello Guri";
  List<int> byte = utf8.encode(str);
  Uint8List plain = Uint8List.fromList(byte);
  print("Plain message in txt: $str");
  print("Plain message in byte: $plain");

  // generating AES key
  Uint8List key = _genAESSymKey();
  // print("AES KEY: $key");

  // encrypt
  _EncryptedData encryptedData = _encryptBytes(plain, key);
  print("Encrypted message in byte: ${encryptedData.encryptedData}");
  print("Encrypted message size: ${encryptedData.encryptedData.length}");

  Uint8List decoded = _decryptBytes(encryptedData, key);
  print("Decrypted message in txt: ${utf8.decode(decoded)}");
  print("Decrypted message in byte: $decoded");

  _EncryptedData data;
  AesGcmChunk en = encryptSetup("./testdata/short_txt.txt");
  if (en.offset + chunkSize >= en.fileSize) {
    // Send last chunk
    data = await en._encryptChunk(en.fileSize - en.offset);
  } else {
    // Send Chunk
    data = await en._encryptChunk(chunkSize);
  }
  print(data.encryptedData);
}
