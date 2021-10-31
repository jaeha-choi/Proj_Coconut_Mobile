import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  Logger.level = Level.debug;
  test("encryption and decryption", () async {
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

    await encrypt.encrypt(test, client1Pub, client2Pri);

    StreamController<Message> controller = StreamController<Message>();

    test.list.forEach((Uint8List element) {
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
        data = element.sublist(6);
      }

      Message msg =
          Message(size, errorsList[errorCode], commandsList[commandCode], data);
      controller.add(msg);
    });

    await decrypt.decrypt(controller.stream, client2Pub, client1Pri);

    // TODO: Use checksum to check if the input and the output is the same
    test.close();
    controller.close();
  });
}
