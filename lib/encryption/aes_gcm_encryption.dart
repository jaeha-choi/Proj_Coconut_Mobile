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
  final Uint8List? _key;
  File file;
  var _stream;

  bool _isEncrypt;

  bool get isEncrypt => _isEncrypt;

  String _fileName;

  String get fileName => _fileName;

  // fileSize is uInt64 check
  int _fileSize;

  int get fileSize => _fileSize;

  // chunkCount is uInt16
  int _chunkCount;

  int get chunkCount => _chunkCount;

  // offset is uInt64 check
  int _offset;

  // chunkNum is uInt16 check
  int _chunkNum;

  AesGcmChunk._(
      this._key,
      this.file,
      this._isEncrypt,
      this._stream,
      this._fileName,
      this._fileSize,
      this._chunkCount,
      this._offset,
      this._chunkNum);

  /// Encrypts file and write to writer
  /// Receiver's pub key is required for encrypting symmetric encryption key
  /// Sender's private key is required for singing the encrypted key
  Future<void> encrypt(SecureSocket writer, RSAPublicKey receiverPubKey,
      RSAPrivateKey senderPrivateKey) async {
    final BytesBuilder keyChNum = BytesBuilder();
    keyChNum.add(this._key!);
    keyChNum.add(uint16ToBytes(this._chunkCount));

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

    _EncryptedData encryptedData =
        _encryptBytes(Uint8List.fromList(utf8.encode(this._fileName)));

    // Send IV (Nonce)
    writeBytes(writer, encryptedData.iv);

    // Send encrypted file name
    writeBytes(writer, encryptedData.encryptedData);

    // Send encrypted file
    // List encryptedFileChunk;

    _EncryptedData encryptedFileChunk;
    // Loop until every byte is sent
    // this.readOffset and this.readChunkNum are updated in encryptedChunk
    while (this._offset < this._fileSize) {
      if (this._offset + chunkSize >= this._fileSize) {
        // Send last chunk
        encryptedFileChunk = await _encryptChunk(this._fileSize - this._offset);
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

    List<int> data = await this.file.openRead(this._offset, chunkSize).single;

    // get Current chunk number
    Uint8List currentChunkNum = uint16ToBytes(this._chunkNum);

    // Plain data is combined with current chunk number to be sent
    plain.add(currentChunkNum);
    plain.add(data);

    // Encrypt chunk of file and return encrypted output, IV, and error, if any.
    _EncryptedData encryptedData = _encryptBytes(plain.takeBytes());

    // Update variables for loop in Encrypt
    this._chunkNum += 1;
    this._offset += plain.length;
    return encryptedData;
  }

  /// Encrypts plain and return encrypted data, IV that was used as [_EncryptedData]
  _EncryptedData _encryptBytes(Uint8List paddedPlaintext) {
    final _seed =
        Uint8List.fromList(List.generate(32, (n) => _random.nextInt(255)));
    final secRnd = SecureRandom("Fortuna")..seed(KeyParameter(_seed));

    final iv = secRnd.nextBytes(IvSize);
    final gcm = GCMBlockCipher(AESFastEngine())
      ..init(true,
          AEADParameters(KeyParameter(this._key!), 128, iv, Uint8List(0)));

    return _EncryptedData(encryptedData: gcm.process(paddedPlaintext), iv: iv);
  }

  /// Decrypts encrypted data with IV and key
  Uint8List _decryptBytes(_EncryptedData data) {
    final gcm = GCMBlockCipher(AESFastEngine())
      ..init(false,
          AEADParameters(KeyParameter(this._key!), 128, data.iv, Uint8List(0)));
    return gcm.process(data.encryptedData);
  }

  // TODO: Testing needed
  Future<void> close() async {
    if (!this.isEncrypt) {
      // Write file
      await (this._stream as IOSink).flush();
      await (this._stream as IOSink).close();

      // Rename file from "temp"
      // https://api.dart.dev/stable/2.14.3/dart-io/File/rename.html
      String path = file.path;
      int lastSeparator = path.lastIndexOf(Platform.pathSeparator);
      String newPath = path.substring(0, lastSeparator + 1) + this.fileName;
      this.file = await file.rename(newPath);
    }
  }
}

/// encryptSetup opens file using[filePath], determine number of chunks, and return
/// [fileName] is a full path of a file. e.g. /foo/bar/cat.jpg
AesGcmChunk encryptSetup(String filename) {
  final File f = File(filename);
  final size = f.lengthSync();
  return AesGcmChunk._(
      _genAESSymKey(), f, true, null, filename, size, size ~/ chunkSize, 0, 0);
}

///decryptSetup creates temporary file, make directory if it doesn't exist then return *AesGcmChunk
AesGcmChunk decryptSetup() {
  // TODO: add download path
  final File f = File("temp");
  return AesGcmChunk._(null, f, false, f.openWrite(), "", 0, 0, 0, 0);
}

Uint8List _genAESSymKey([int length = 32]) {
  var values = List<int>.generate(length, (i) => _random.nextInt(256));
  Uint8List res = Uint8List.fromList(values);
  // return base64Url.encode(values); ??
  return res;
}

Future<void> main() async {
  AesGcmChunk encrypter = encryptSetup("./testdata/short_txt.txt");
  // encrypter.encrypt(writer, receiverPubKey, senderPrivateKey);
}
