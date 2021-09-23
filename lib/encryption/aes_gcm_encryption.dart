import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import "package:pointycastle/export.dart";

// const int ChunkSize = 16777216;

main() {
  final pair = generateRSAkeyPair(exampleSecureRandom());
  final public = pair.publicKey;
  final private = pair.privateKey;

}
// encryptSetup opens file, determine number of chunks, and return TODO
void encryptSetup() {
  // Message we want to encrypt
  final message = utf8.encode('Hello encryption!');
  

  // Generate symmetric encryption key

  // Open file

  // Get size of source file

  // Get the name of the file

  // Get number of chunks
}

// generateRSAkeyPair creates public and private key using RSA(Asymmetric algo)
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom));

  // Use the generator

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

// exampleSecureRandom creates Fortuna random number generator
SecureRandom exampleSecureRandom() {

  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
  return secureRandom;
}



// genSymKey generates random key for symmetric encryption



// Encrypt file and write to writer
// Receiver's pub key is required for encrypting symmetric encryption key.
// Sender's private key is required for singing the encrypt key.
Future<void> encrypt(RawSocket writer, RSAPublicKey,  RSAPrivateKey) async {
  Uint8List list ;
  // Encrypt and sign symmetric encryption key
  rsaEncrypt(RSAPublicKey, list);
  // final secretKey = SecretKey(RSAPublicKey);


  // final algorithm = AesCtr.with256bits(macAlgorithm: );


  // final keyPair = await algorithm.newKeyPair();
  // final pubkey = await algorithm.newKeyPair();
//   // Choose the cipher. We use AES-CTR(Counter mode)
//   // AES-CTR with 32 bytes keys and Hmac-SHA 256 authentication.
//   final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
//
//   // Generate a random secret (symmetric) key.
//   final secretKey = await algorithm.newSecretKey();
//   // final secretKeyBytes = await secretKey.extractBytes();
//
//   // Nounce length is 12 bytes by default.That means 4 bytes is used for block counter.
//   //
//   //     Because block is 16 bytes, maximum message size is 32 GB with a single nonce.
//   final nonce = algorithm.newNonce();
//   print('Secret key: ${secretKey}');
//
//
//   // Encrypt
//   final secretBox = await algorithm.encrypt(message, secretKey: secretKey,);
//   print('Nonce: ${secretBox.nonce}');
//   print('Ciphertext: ${secretBox.cipherText}');
//   print('MAC: ${secretBox.mac.bytes}');
//
//   // Decrypt
//   final clearText = await algorithm.decrypt(
//   secretBox,
//   secretKey: secretKey,
//   );
//   print('Cleartext: ${utf8.decode(clearText)
//   }
//   '
//   );
}


Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(myPrivate)); // false=decrypt

  return _processInBlocks(decryptor, cipherText);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = input.length ~/ engine.inputBlockSize +
      ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

  final output = Uint8List(numBlocks * engine.outputBlockSize);

  var inputOffset = 0;
  var outputOffset = 0;
  while (inputOffset < input.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
        ? engine.inputBlockSize
        : input.length - inputOffset;

    outputOffset += engine.processBlock(
        input, inputOffset, chunkSize, output, outputOffset);

    inputOffset += chunkSize;
  }

  return (output.length == outputOffset)
      ? output
      : output.sublist(0, outputOffset);
}

//
// Future<void> main() async {
//   final algorithm = RsaPss(
//     hashAlgorithm: ,
//  );
//
//   // Generate a key pair
//   final keyPair = await algorithm.newKeyPair();
//
//   // Sign a message
//   final message = <int>[1,2,3];
//   final signature = await algorithm.sign(
//     message,
//     keyPair: keyPair,
//   );
//   print('Signature bytes: ${signature.bytes}');
//   print('Public key: ${signature.publicKey.bytes}');
//
//   // Anyone can verify the signature
//   final isSignatureCorrect = await algorithm.verify(
//     message,
//     signature: signature,
//   );
// }
