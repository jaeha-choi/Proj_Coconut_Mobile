import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import 'package:mobile_app/encryption/aes_gcm_encryption.dart';
import 'package:mobile_app/utils/commands.dart';
import 'package:mobile_app/utils/error.dart';
import 'package:mobile_app/utils/util.dart';

/// ByteStream is a class to "emulate" the server
///
class ByteStream implements IOSink {
  Completer completer = Completer();
  BytesBuilder buffer = BytesBuilder();
  List<Uint8List> list = List.empty(growable: true);

  void add(List<int> data) {
    this.buffer.add(data);
    this.list.add(this.buffer.takeBytes());
  }

  @override
  String toString() {
    return this.list.toString();
  }

  @override
  Future close() {
    this.buffer.clear();
    this.completer.complete();
    return completer.future;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Creates new [Client] and return it.
/// Returns null upon error.
Future<Client> newClient() async {
  // Open RSA keys, if the user already got one
  Logger.level = Level.debug;

  // final client1 = CryptoUtils.generateRSAKeyPair(keySize: 4096);
  // print(pubKey);
  // RSAPrivateKey privKey = client1.privateKey as RSAPrivateKey;
  String appDocDir = './testdata';
  bool isPub = File('$appDocDir/key.pub').existsSync();
  bool isPriv = File('$appDocDir/key.priv').existsSync();

  if (!(isPub && isPriv)) {
    List lis = await createPemFile(appDocDir);
    String pubKey = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(lis.first);
    return new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      // conn: null,
      privKey: lis.last,
      pubKeyBlock: pubKey,
      addCode: "",
      mapOfChannel: new Map<String, StreamController<Message>>(),
    );
  } else {
    // Public key needs to be in a string format
    String pubKey = File('$appDocDir/key.pub').readAsStringSync();
    // Private key needs to be in a PEM format
    RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPemPkcs1(
        File('$appDocDir/key.priv').readAsStringSync());
    return new Client(
      serverIP: "127.0.0.1",
      serverPort: 9129,
      // conn: null,
      privKey: privateKey,
      pubKeyBlock: pubKey,
      addCode: "",
      mapOfChannel: new Map<String, StreamController<Message>>(),
    );
  }
}

/// Creates [RSAPublicKey] & [RSAPrivateKey] and save them locally.
/// Returns true if PEM files are created, false otherwise.
Future<List> createPemFile(String appDocPath) async {
  try {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: rsaKeySize);
    // Examine the generated key-pair
    final rsaPublic = pair.publicKey as RSAPublicKey;
    final rsaPrivate = pair.privateKey as RSAPrivateKey;

    File('$appDocPath/key.priv').writeAsStringSync(
        CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(rsaPrivate));
    File('$appDocPath/key.pub')
        .writeAsStringSync(CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic));

    return [rsaPublic, rsaPrivate];
  } catch (e) {
    print(e);
  }
  return [];
}

Future<void> writeBinary(IOSink writer, String filename,
    RSAPublicKey receiverPubKey, RSAPrivateKey senderPrivateKey) async {
  AesGcmChunk encrypt = encryptSetup(filename);
  await encrypt.encrypt(writer, receiverPubKey, senderPrivateKey);
}

Message readMessage(Uint8List element) {
  int size = bytesToUint32(element);
  int errorCode = element[4];
  int commandCode = element[5];
  Uint8List data = Uint8List(0);
  if (errorCode != 0) {
    // if errorCode is not in Error class, then return unknown Error
    if (!errorsList.asMap().containsKey(errorCode)) {
      errorCode = UnknownCodeError.code;
    }
  }
  if (size != 0) {
    print(data);
    data = readNBytes(element, size);
    data = data.sublist(6);
    // print(data);
  }

  Message msg =
      Message(size, errorsList[errorCode], commandsList[commandCode], data);

  return msg;
}

Uint8List readNBytes(Uint8List reader, int size) {
  try {
    Uint8List data = reader.sublist(6, size);
    return data;
  } catch (e) {
    print(e);
    return Uint8List(0);
  }
}

void main() async {
  Client robin = await newClient();
  robin.connect();
  RSAPublicKey robinPub =
      CryptoUtils.rsaPublicKeyFromPemPkcs1(robin.pubKeyBlock);
  // create robin public key
  String jaehaPubStr = File('./testdata/jaehaPub.pub').readAsStringSync();

  RSAPublicKey jaehaPub = CryptoUtils.rsaPublicKeyFromPemPkcs1(jaehaPubStr);

  String fileName = "./testdata/short_txt.txt";
  ByteStream test = ByteStream();

  // await writeBinary(test, fileName, jaehaPub, robin.privKey);

  // print(robin.pubKeyBlock);
  // print(test.list);d

  // ByteStream test2 = ByteStream();

  AesGcmChunk decrypt = decryptSetup();

  StreamController<Message> controller = StreamController<Message>();
  while (data.length != 0) {
    controller.add(readMessage(data));
    print('count');
  }

  // test2.list.forEach((Uint8List element) {
  //   int size = bytesToUint32(element);
  //   print(size);
  //   int errorCode = element[4];
  //   // print(errorCode);
  //   int commandCode = element[5];
  //   // print(commandCode);
  //   Uint8List data = Uint8List(0);
  //   if (errorCode != 0) {
  //     // if errorCode is not in Error class, then return unknown Error
  //     if (!errorsList.asMap().containsKey(errorCode)) {
  //
  //       errorCode = UnknownCodeError.code;
  //     }
  //   }
  //   if (size != 0) {
  //     data = element.sublist(6);
  //     // print(data);
  //   }
  //
  //   Message msg =
  //   Message(size, errorsList[errorCode], commandsList[commandCode], data);
  //
  //   controller.add(msg);
  // });

  print('here');

  await decrypt.decrypt(controller.stream, jaehaPub, robin.privKey);
}
