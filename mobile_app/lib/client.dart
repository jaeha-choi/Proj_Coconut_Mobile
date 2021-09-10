import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import "package:pointycastle/export.dart";
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'dart:core';

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // TODO rsaBit length should be 4096? (Jaeha used 4096)
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

SecureRandom exampleSecureRandom() {
  final secureRandom = FortunaRandom();

  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  return secureRandom;
}

// List<int> keyData = PemCodec(PemLabel.publicKey).decode(public);

// String pemBlock = PemCodec(PemLabel.publicKey).encode(keyData);

void openKeys() {
  final pair = generateRSAkeyPair(exampleSecureRandom());
  final public = pair.publicKey;
  final private = pair.privateKey;
}

class Client {
  String serverIP; //TODO yaml?
  int serverPort; //TODO yaml?
  SecureSocket secureServer;

  // AsymmetricKeyPair privKey;
  var privKey;
  var pubKeyBlock;
  String addCode;

  Client({
    String serverIP,
    int serverPort,
    SecureSocket secureServer,
    var privKey,
    var pubKeyBlock,
    String addCode,
  })  : this.serverIP = serverIP,
        this.serverPort = serverPort,
        this.secureServer = secureServer ,
        this.privKey = privKey,
        this.pubKeyBlock = pubKeyBlock,
        this.addCode = addCode;
}

Client newClient() {
  // RSAKeyGenerator keyGen = ...

  final pair = generateRSAkeyPair(
      exampleSecureRandom()); // produces an AsymmetricKeyPair

// Examine the generated key-pair

  final rsaPublic = pair.publicKey as RSAPublicKey;
  final rsaPrivate = pair.privateKey as RSAPrivateKey;

  print('Generated ${generateRSAkeyPair} key:');
  print('  Public:');
  print('    e = ${rsaPublic.exponent}'); // public exponent
  print('    n = ${rsaPublic.modulus}'); // <= TODO pubBlock?
  print('  Private: n.bitlength = ${rsaPrivate.modulus.bitLength}');
  print('    n = ${rsaPrivate.modulus}');
  print('    d = ${rsaPrivate.exponent}'); // private exponent
  print('    p = ${rsaPrivate.p}'); // the two prime numbers
  print('    q = ${rsaPrivate.q}');

  Client client =
      new Client(serverIP: "127.0.0.1", serverPort: 9199,
          privKey: rsaPrivate, pubKeyBlock: rsaPublic.modulus);

  return client;
}

void connect() {}

void main() {
  newClient();
}
