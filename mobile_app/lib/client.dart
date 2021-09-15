import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:logger/logger.dart';
import "package:pointycastle/export.dart";
import 'dart:io';
import 'dart:core';
import 'rsa_key_helper.dart';
import 'logger.dart';
import 'package:pointycastle/api.dart';

final logger = Logger(printer: SimpleLogPrinter('client.dart'));

// List<int> keyData = PemCodec(PemLabel.publicKey).decode(public);
// String pemBlock = PemCodec(PemLabel.publicKey).encode(keyData);

class Client {
  String serverIP; //TODO yaml?
  int serverPort; //TODO yaml?
  SecureSocket  conn;
  RSAPrivateKey privKey;
  String pubKeyBlock;
  String addCode;

  Client({
    String serverIP,
    int serverPort,
    SecureSocket  conn,
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
  try {
    logger.d('Connecting....');
    // ConnectionTask dial1; <= TODO Return type?
    ConnectionTask<SecureSocket> connection;
    connection = await SecureSocket.startConnect(
      client.serverIP,
      client.serverPort,
      onBadCertificate: (certificate) => true,
    );
    client.conn = await connection.socket;

    // Initializing client
    doInit(client);
  }catch(e){
    logger.d('Error in connect() :$e');
  }
}

void doInit(Client client) {
  // print(client.pubKeyBlock);
  Uint8List pubKeyHash = PemToSha256(client.pubKeyBlock);
  print(pubKeyHash);
  print(client.conn);
  writeString(client.conn, pubKeyHash);
}

/// PemToSHA256
/// Given pubKey [String] convert it to hashString
Uint8List PemToSha256(String pubKey)  {
  // Convert string to byte
  var uint8List = Uint8List.fromList(pubKey.codeUnits);

  // * actual information converted into byte
  // sha256sum always returns 32 bytes
  var sha256 = Digest("SHA-256").process(uint8List);
  // String hashStr = hex.encode(sha256);
  return sha256;
}

/// WriteString writes message to writer
/// length of message cannot exceed BufferSize
/// returns <total bytes sent, error>
List writeString(SecureSocket writer, Uint8List bytes) {
  try {
    // Convert string to byte
    // Get size(uint32) of total bytes to send
    var size = uint32ToByte(bytes.length);
    logger.d( bytes.length);
    logger.d( size);
    // logger.d( utf8.encode(size.toString()));

    writer.add(size);
    writeErrorCode(writer);
    logger.d(bytes);
    writer.add(bytes);

    return [size, true];
  } catch (error) {
    logger.d('Error in writeString() :$error');
    return [0, false];
  }
}

void writeErrorCode(SecureSocket writer){ // [0,0,0,0,0,0,0,0]
  final code = Uint8List(1);// [255] = [1,1,1,1,1,1,1,1] = 8 bits = 1 byte
  print(code);

  // print(code.runtimeType);
  // Write 1 byte of error code
  try{
    writer.add(code);

  }catch(e){
    logger.d('Error in writeErrorCode() :$e');
  }


}

// Unsigned int32 to byte
Uint8List uint32ToByte(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

Future<void> main() async {
  Logger.level = Level.debug;
  Client client = await newClient();
  connect(client);


}
