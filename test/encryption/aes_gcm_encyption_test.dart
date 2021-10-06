import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import 'package:mobile_app/encryption/aes_gcm_encryption.dart';

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
  Client? client1 = await newClient();
  Client? client2 = await newClient();
  AesGcmChunk encrypt = encryptSetup("./testdata/short_txt.txt");
  AesGcmChunk decrypt = decryptSetup();
  ByteStream test = ByteStream();

  // test.add(Uint8List.fromList([0,1,2,3]));
  // test.add(Uint8List.fromList([3,2,1,0]));
  // print(test);

  await encrypt.encrypt(
      test,
      CryptoUtils.rsaPublicKeyFromPemPkcs1(client1!.pubKeyBlock),
      client2!.privKey);

  StreamIterator<Uint8List> testIter =
      StreamIterator(Stream.fromIterable(test.list));

  await decrypt.decrypt(
      testIter,
      CryptoUtils.rsaPublicKeyFromPemPkcs1(client2.pubKeyBlock),
      client1.privKey);

  // TODO: Use checksum to check if the input and the output is the same

  await test.close();
}
