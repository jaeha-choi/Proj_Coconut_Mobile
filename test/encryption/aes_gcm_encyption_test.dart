import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import 'package:mobile_app/encryption/aes_gcm_encryption.dart';
import 'package:mobile_app/utils/commands.dart';
import 'package:mobile_app/utils/error.dart';

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

Future<void> main() async {
  Logger.level = Level.debug;
  // Client client1 = await newClient();
  // Client client2 = await newClient();

  Uint8List plain = Uint8List.fromList(utf8.encode("Hello Guri"));
  print(plain);

  final client1 = CryptoUtils.generateRSAKeyPair(keySize: 4096);
  final client2 = CryptoUtils.generateRSAKeyPair(keySize: 4096);

  RSAPublicKey client1Pub = client1.publicKey as RSAPublicKey;
  RSAPrivateKey client1Pri = client1.privateKey as RSAPrivateKey;

  RSAPublicKey client2Pub = client2.publicKey as RSAPublicKey;
  RSAPrivateKey client2Pri = client2.privateKey as RSAPrivateKey;

  AesGcmChunk encrypt = encryptSetup("./testdata/short_txt.txt");
  AesGcmChunk decrypt = decryptSetup();
  ByteStream test = ByteStream();

  // test.add(Uint8List.fromList([0,1,2,3]));
  // test.add(Uint8List.fromList([3,2,1,0]));

  await encrypt.encrypt(
      test,
      // CryptoUtils.rsaPublicKeyFromPemPkcs1(client1.pubKeyBlock),
      client1Pub,
      client2Pri);
  // client2.privKey);

  StreamIterator<Uint8List> testIter =
      StreamIterator(Stream.fromIterable(test.list));
  // print(test.list.length);
  // print(test.list);
  Message msg = Message(test.list.length, NoError, Init, test.list[0]);
  StreamController<Message> stream = StreamController<Message>();
  stream.add(msg);

  //Stream<Message> steam,
  // TODO: Update parameter type and format
  await decrypt.decrypt(
      stream.stream,
      // CryptoUtils.rsaPublicKeyFromPemPkcs1(client2.pubKeyBlock),
      // client1.privKey);
      client2Pub,
      client1Pri);

  // TODO: Use checksum to check if the input and the output is the same
  await test.close();
}
