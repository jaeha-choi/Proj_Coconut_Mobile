import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import 'package:mobile_app/encryption/rsa.dart';
import 'package:mobile_app/utils/commands.dart';
import 'package:mobile_app/utils/error.dart';
import 'package:path/path.dart' as p;
import "package:pointycastle/export.dart";

import '../utils/util.dart';

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
const DownloadPath = "./download";

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
  Uint8List? _key;
  File file;
  var _stream;

  bool _isEncrypt;

  bool get isEncrypt => _isEncrypt;

  String _filePath;

  String get fileName => _filePath;

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
      this._filePath,
      this._fileSize,
      this._chunkCount,
      this._offset,
      this._chunkNum);

  /// Encrypts file and write to writer
  /// Receiver's pub key is required for encrypting symmetric encryption key
  /// Sender's private key is required for singing the encrypted key
  Future<void> encrypt(IOSink writer, RSAPublicKey receiverPubKey,
      RSAPrivateKey senderPrivateKey) async {
    final BytesBuilder keyChNum = BytesBuilder();
    keyChNum.add(this._key!);
    keyChNum.add(uint16ToBytes(this._chunkCount));

    // Encrypt and sign symmetric encryption key
    Uint8List encryptData = encryptMsg(keyChNum.takeBytes(), receiverPubKey);
    print(encryptData);
    // Send encrypted symmetric key
    try {
      writeBytes(writer, encryptData, FileCommand, NoError);
    } catch (e) {
      logger.d("Error in writeBytes while sending data encrypted");
    }

    // sign the symmetric encryption key
    Uint8List dataSignature =
        CryptoUtils.rsaSign(senderPrivateKey, encryptData);
    print(dataSignature);
    // Send encrypted symmetric key signature
    try {
      writeBytes(writer, dataSignature, FileCommand, NoError);
    } catch (e) {
      logger.d("Error in writeBytes while sending data signature");
    }

    // Only send file name, not a path
    int lastSeparator = this._filePath.lastIndexOf(Platform.pathSeparator);
    String newPath = this._filePath.substring(lastSeparator + 1);

    _EncryptedData encryptedData =
        _encryptBytes(Uint8List.fromList(utf8.encode(newPath)));

    // Send IV (Nonce)
    writeBytes(writer, encryptedData.iv, FileCommand, NoError);

    // Send encrypted file name
    writeBytes(writer, encryptedData.encryptedData, FileCommand, NoError);

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
      writeBytes(writer, encryptedFileChunk.iv, FileCommand, NoError);

      // Send encrypted file chunk + current chunk number (first two bytes)
      writeBytes(
          writer, encryptedFileChunk.encryptedData, FileCommand, NoError);
    }
    this.close();
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
    this._offset += data.length;
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

  /// Decrypts encrypted data from reader and decrypts the file
  /// Sender's public ket is required for verifying signature
  /// Receiver's private key is required for decrypting symmetric encryption key
  Future<void> decrypt(Stream<Message> stream, RSAPublicKey senderPubKey,
      RSAPrivateKey receiverPrivKey) async {
    StreamIterator<Message> iter = StreamIterator<Message>(stream);
    // Reads encrypted symmetric encryption key
    Message dataEncryptedMsg = await readBytes(iter);
    print(dataEncryptedMsg.data);
    Uint8List dataEncrypted = dataEncryptedMsg.data;
    if (dataEncrypted == Uint8List(0)) {
      logger.d("Error in readBytes while getting dataEncrypted");
    }

    // Reads signature for encrypted symmetric encryption key
    Message dataSignatureMsg = await readBytes(iter);
    print(dataSignatureMsg.data);
    Uint8List dataSignature = dataSignatureMsg.data;
    if (dataSignature == Uint8List(0)) {
      logger.d("Error in readBytes while getting dataEncrypted");
    }
    // verify and decrypts symmetric encryption key
    Uint8List dataPlain = decryptVerifyMsg(
        dataEncrypted, dataSignature, senderPubKey, receiverPrivKey);

    this._key = Uint8List.fromList(dataPlain.take(SymKeySize).toList());
    this._chunkCount =
        bytesToUint16(Uint8List.fromList(dataPlain.skip(SymKeySize).toList()));

    // Get IV for decrypting file name
    Message ivFileNameMsg = await readBytes(iter);
    Uint8List ivFileName = ivFileNameMsg.data;
    if (ivFileName == Uint8List(0)) {
      logger.d("Error while reading iv for file name");
    }

    // Get encrypted file name
    Message encryptedFileNameMsg = await readBytes(iter);
    Uint8List encryptedFileName = encryptedFileNameMsg.data;
    if (encryptedFileName == Uint8List(0)) {
      logger.d("Error while reading encrypted file name");
    }

    // Decrypt file name with encrypted data and IV
    Uint8List decryptFileName = _decryptBytes(
        _EncryptedData(encryptedData: encryptedFileName, iv: ivFileName));
    if (decryptFileName == Uint8List(0)) {
      logger.d("Error while decrypting file name");
    }

    // Update file name
    this._filePath = utf8.decode(decryptFileName);

    // Receive file and decrypt
    Uint8List decryptFileChunk;
    // Loop until every byte is fully received
    // this.readOffset and this.readChunkNum are updated in encryptedChunk
    while (this._chunkNum < this._chunkCount) {
      // read IV in plain text
      Message ivMsg = await readBytes(iter);

      Uint8List iv = ivMsg.data;
      if (iv == Uint8List(0)) {
        logger.d("Error in readBytes while reading IV");
      }

      // Read encrypted file chunk + current chunk number (first two bytes)
      Message encryptedFileChunkMsg = await readBytes(iter);
      Uint8List encryptedFileChunk = encryptedFileChunkMsg.data;
      if (encryptedFileChunk == Uint8List(0)) {
        logger.d("Error in readBytes while reading encryptedFileChunk");
      }

      // Decrypt file chunk + current chunk number (first two bytes)
      _EncryptedData encryptData =
          _EncryptedData(encryptedData: encryptedFileChunk, iv: iv);

      decryptFileChunk = _decryptChunk(encryptData);

      // Write decrypted data to temp file
      (this._stream as IOSink).add(decryptFileChunk);
      // await this.file.writeAsBytes(decryptFileChunk, mode: FileMode.append);
    }
    this.close();
  }

  Uint8List _decryptChunk(_EncryptedData encryptData) {
    // Decrypt data
    Uint8List decryptedData = _decryptBytes(encryptData);

    // Convert chunk number bytes to uint16 (first two bytes)
    int currChunkNum =
        bytesToUint16(Uint8List.fromList(decryptedData.take(2).toList()));
    Uint8List decryptedFileChunk =
        Uint8List.fromList(decryptedData.skip(2).toList());
    // If chunk was received in incorrect order, raise error
    if (this._chunkNum != currChunkNum) {
      logger.d("Encrypted chunk was received in an incorrect order");
      // return?
    }

    // Update variables for loop in Decrypt
    this._chunkNum += 1;
    this._offset += decryptedFileChunk.length;

    return decryptedFileChunk;
  }

  /// Decrypts encrypted data with IV and key
  Uint8List _decryptBytes(_EncryptedData data) {
    final gcm = GCMBlockCipher(AESFastEngine())
      ..init(false,
          AEADParameters(KeyParameter(this._key!), 128, data.iv, Uint8List(0)));
    return gcm.process(data.encryptedData);
  }

  /// Decrypts key for symmetric encryption with receiver's private key, and verify signature with sender's public key
  Uint8List decryptVerifyMsg(Uint8List encryptedMsg, Uint8List signature,
      RSAPublicKey senderPubKey, RSAPrivateKey receiverPrivKey) {
    // Decrypt symmetric encryption key
    Uint8List symKey = rsaDecrypt(encryptedMsg, receiverPrivKey);
    // Verify symmetric encryption key signature
    bool verify = rsaVerify(senderPubKey, encryptedMsg, signature);
    if (!verify) {
      logger.d("Error while decrypting symmetric encryption key");
    }
    return symKey;
  }

  Future<void> close() async {
    if (!this.isEncrypt) {
      // Write file
      await (this._stream as IOSink).flush();
      await (this._stream as IOSink).close();

      // Rename file from "temp"
      this.file = await file.rename(p.join(DownloadPath, this.fileName));
    }
  }
}

/// encryptSetup opens file using[filePath], determine number of chunks, and return
/// [fileName] is a full path of a file. e.g. /foo/bar/cat.jpg
AesGcmChunk encryptSetup(String filename) {
  final File f = File(filename);
  final size = f.lengthSync();
  return AesGcmChunk._(_genAESSymKey(), f, true, null, filename, size,
      (size / chunkSize).ceil(), 0, 0);
}

///decryptSetup creates temporary file, make directory if it doesn't exist then return *AesGcmChunk
AesGcmChunk decryptSetup() {
  // Concurrent transfer probably requires different file names
  final File f = File(p.join(DownloadPath, "temp.tmp"));
  f.createSync(recursive: true);
  return AesGcmChunk._(
      null, f, false, f.openWrite(mode: FileMode.write), "", 0, 0, 0, 0);
}

Uint8List _genAESSymKey([int length = 32]) {
  var values = List<int>.generate(length, (i) => _random.nextInt(256));
  Uint8List res = Uint8List.fromList(values);
  // return base64Url.encode(values); ??
  return res;
}

Future<void> main() async {
  // AesGcmChunk encrypter = encryptSetup("./testdata/short_txt.txt");
  // encrypter.encrypt(writer, encrypter._key, senderPrivateKey)
  // AesGcmChunk decrtpyer = decryptSetup();
  // encrypter.encrypt(writer, receiverPubKey, senderPrivateKey);
}
