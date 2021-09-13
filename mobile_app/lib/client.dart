import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pem/pem.dart';
import "package:pointycastle/export.dart";
import 'dart:io';
import 'dart:core';
import 'rsa_key_helper.dart';


// Generating RSA (Asymmetric encryption)
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 4096}) {
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

// SecureRandom (Fortuna)
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

class Client {
  String serverIP; //TODO yaml?
  int serverPort; //TODO yaml?
  RawSocket conn;

  RSAPrivateKey privKey;
  RSAPublicKey pubKeyBlock;
  String addCode;

  Client({
    String serverIP,
    int serverPort,
    RawSocket conn,
    RSAPrivateKey privKey,
    RSAPublicKey pubKey,
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


// https://medium.com/flutter-community/asymmetric-key-generation-in-flutter-ad2b912f3309
String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {

  var topLevel = new ASN1Sequence();

  var version = ASN1Integer(BigInt.from(0));
  var modulus = ASN1Integer(privateKey.n);
  var publicExponent = ASN1Integer(privateKey.exponent);
  var privateExponent = ASN1Integer(privateKey.d);
  var p = ASN1Integer(privateKey.p);
  var q = ASN1Integer(privateKey.q);
  var dP = privateKey.d % (privateKey.p - BigInt.from(1));
  var exp1 = ASN1Integer(dP);
  var dQ = privateKey.d % (privateKey.q - BigInt.from(1));
  var exp2 = ASN1Integer(dQ);
  var iQ = privateKey.q.modInverse(privateKey.p);
  var co = ASN1Integer(iQ);

  topLevel.add(version);
  topLevel.add(modulus);
  topLevel.add(publicExponent);
  topLevel.add(privateExponent);
  topLevel.add(p);
  topLevel.add(q);
  topLevel.add(exp1);
  topLevel.add(exp2);
  topLevel.add(co);

  var dataBase64 = base64.encode(topLevel.encodedBytes);

  return """-----BEGIN RSA PRIVATE KEY-----\r\n$dataBase64\r\n-----END RSA PRIVATE KEY-----""";
}

//pem -> key is decode
// key -> pem is encode
Client newClient() {
  // Open RSA keys, if the user already got one
  bool ifFileExist = File('key.priv').existsSync();
  // print(ifFileExist);
  String pub ='';
  String priv='';
  try {
    if (ifFileExist == true) {
      // Use existing pem file
      pub =  File('key.pub').readAsStringSync();
      priv = File('key.priv').readAsStringSync();
    }
    // Create pem file
    else {
      createPemFile();
    }

    // Decode public key //TODO creating block is same thing as a decoding??
    RSAPublicKey pubKey = parsePublicKeyFromPem(pub);

    // Decode private key
    RSAPrivateKey privateKey = parsePrivateKeyFromPem(priv);
    // Print number of bytes in the key, we could obviously also pass it to
    // another library to use the key.

    // print('private key contains ${privateKeydata.length} bytes');

    Client client = new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      conn: null,
      privKey: privateKey,
      pubKey: pubKey, // TODO jaeha used pubkey block which is decode file and created block
    );
    return client;
  } catch (e) {
    print("Error while creating/finding PEM file:");
    print(e);
  }
}


Future<void> createPemFile() async {
  // RSAKeyGenerator keyGen = ...
  final pair = generateRSAkeyPair(
      exampleSecureRandom()); // produces an AsymmetricKeyPair

// Examine the generated key-pair
  final rsaPublic = pair.publicKey as RSAPublicKey;
  final rsaPrivate = pair.privateKey as RSAPrivateKey;
  // print(encodePublicKeyToPemPKCS1(rsaPublic));
  // print(encodePrivateKeyToPemPKCS1(rsaPrivate));
  await File('key.priv').writeAsString(encodePrivateKeyToPemPKCS1(rsaPrivate));
  await File('key.pub').writeAsString(encodePublicKeyToPemPKCS1(rsaPublic));
}

void connect(Socket conn, Client client) {
  SecureSocket.secure(conn);
}

void main() {
  newClient();

}
