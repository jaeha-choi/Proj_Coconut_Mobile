import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import "package:pointycastle/export.dart";

import '../utils/util.dart';

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

/// Encrypt the given [message] using the given RSA [publicKey].
/// Sign with the [privateKey]
/// We copied this function from CryptoUtil
/// https://github.com/Ephenodrom/Dart-Basic-Utils#cryptoutils
List encryptSignMsg(
    Uint8List data, RSAPublicKey publicKey, RSAPrivateKey privateKey) {
  RSAEngine cipher = RSAEngine()
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  Uint8List encryptData = cipher.process(data);

  // sign the symmetric encryption key
  Uint8List dataSignature = CryptoUtils.rsaSign(privateKey, encryptData);
  return [encryptData, dataSignature];
}

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
Future<bool> createPemFile(String appDocPath) async {
  try {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: rsaKeySize);

    // Examine the generated key-pair
    final rsaPublic = pair.publicKey as RSAPublicKey;
    final rsaPrivate = pair.privateKey as RSAPrivateKey;

    File('$appDocPath/key.priv').writeAsStringSync(
        CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(rsaPrivate));
    File('$appDocPath/key.pub')
        .writeAsStringSync(CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic));

    return true;
  } catch (e) {
    logger.e('Error in createPemFile() $e');
  }
  return false;
}

/// Convert PEM formatted string [pubKey] to SHA256 bytes
Uint8List pemToSha256(String pubKey) {
  // Convert string to byte
  var byte = Uint8List.fromList(pubKey.codeUnits);
  return Digest("SHA-256").process(byte);
}

/// Verifies the RSA signature
/// Returns true if it is a valid signature
bool rsaVerify(RSAPublicKey publicKey, Uint8List signedData, Uint8List signature,{String algorithm = 'SHA-256/RSA'}){
  return CryptoUtils.rsaVerify(publicKey, signedData, signature);
}


/// Decrypt the given [cipherMessage] using the given RSA [privateKey].
Uint8List rsaDecrypt(Uint8List cipherByte, RSAPrivateKey privateKey){
  var cipher = RSAEngine()
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return cipher.process(Uint8List.fromList(cipherByte));
}


Future<void> main() async {
  String str = "Hello Guri";
  List<int> byte = utf8.encode(str);
  Uint8List plain = Uint8List.fromList(byte);
  print("Plain message in txt: $str");
  print("Plain message in byte: $plain");
  Client? clinet = await newClient();

  RSAPublicKey pubkey =
      CryptoUtils.rsaPublicKeyFromPemPkcs1(clinet.pubKeyBlock);
  List encrypt = encryptSignMsg(plain, pubkey, clinet.privKey);

  print(rsaVerify(pubkey, encrypt.first, encrypt.last));

  print(rsaDecrypt(encrypt.first, clinet.privKey));
}