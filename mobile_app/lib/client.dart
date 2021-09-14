import 'dart:convert';
import 'package:asn1lib/asn1lib.dart';
import 'package:logger/logger.dart';
import "package:pointycastle/export.dart";
import 'dart:io';
import 'dart:core';
import 'rsa_key_helper.dart';
import 'logger.dart';

final logger = Logger(printer: SimpleLogPrinter('client.dart'));

// List<int> keyData = PemCodec(PemLabel.publicKey).decode(public);
// String pemBlock = PemCodec(PemLabel.publicKey).encode(keyData);

class Client {
  String serverIP; //TODO yaml?
  int serverPort; //TODO yaml?
  RawSocket conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;

  Client({
    String serverIP,
    int serverPort,
    RawSocket conn,
    RSAPrivateKey privKey,
    String pubKey,
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

//pem -> key is decode
// key -> pem is encode
Future<Client> newClient() async {
  // Open RSA keys, if the user already got one
  bool ifPubFileExist = File('key.pub').existsSync();
  bool ifPrivFileExist = File('key.priv').existsSync();
  String pubKey = '';
  // String privKey = '';
  try {
    if (ifPubFileExist == true && ifPrivFileExist == true) {
      // Use existing pem file
      pubKey = File('key.pub').readAsStringSync();
    }
    // Create pem file
    else {
      await createPemFile();
      pubKey = File('key.pub').readAsStringSync();
    }

    // Decode Private key from PEM Format
    RSAPrivateKey privateKey =
        parsePrivateKeyFromPem(File('key.priv').readAsStringSync());

    Client client = new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      conn: null,
      privKey: privateKey,
      pubKey: pubKey,
    );
    return client;
  } catch (e) {
    logger.d("ERROR in Client newClient(): $e");
  }
}

/// Creates [RSAPublicKey] & [RSAPrivateKey] and save them locally
/// TODO First time creating a file might take a lot. Maybe return String??
Future<void> createPemFile() async {
  // RSAKeyGenerator keyGen = ...
  try {
    final pair = generateRSAkeyPair(
        exampleSecureRandom()); // produces an AsymmetricKeyPair

    // Examine the generated key-pair
    final rsaPublic = pair.publicKey as RSAPublicKey;
    final rsaPrivate = pair.privateKey as RSAPrivateKey;
    // print(encodePublicKeyToPemPKCS1(rsaPublic));
    // print(encodePrivateKeyToPemPKCS1(rsaPrivate));
    await File('key.priv')
        .writeAsString(encodePrivateKeyToPemPKCS1(rsaPrivate));
    await File('key.pub').writeAsString(encodePublicKeyToPemPKCS1(rsaPublic));
    // return encodePrivateKeyToPemPKCS1(rsaPrivate);

  } catch (e) {
    print(e);
    logger.d('Error in createPemFile() $e');
  }
}

/// connects to a socket with TLS
void connect(Client client) async {
  // client = newClient() as Client;

  SecureSocket.startConnect(
    client.serverIP,
    client.serverPort,
    onBadCertificate: (certificate) => true,
  );
}

Future<void> main() async {
  Logger.level = Level.debug;
  Client client = await newClient();
  connect(client);
}
