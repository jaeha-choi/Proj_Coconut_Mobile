import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';
import 'package:mobile_app/encryption/aes_gcm_encryption.dart';
import 'package:mobile_app/encryption/ffi_rsa.dart';
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
    ByteStream test = ByteStream();
    StreamController<Message> controller = StreamController<Message>();

    // ----- Encryption -----
    // Cat encrypts a file for Fox
    String cat = "./testdata/keypair1/cat";
    String fox = "./testdata/keypair2/fox.pub";

    AesGcmChunk encrypt = encryptSetup("./testdata/short_txt.txt");
    EncryptSign es = EncryptSign(fox, cat);
    int res = es.createSymKeys(1);
    if (res < 1) {
      // TODO: Error handling
      print("error");
    }

    await encrypt.encrypt(test, es.keys[0]);
    es.close();
    // ----- Encryption End -----

    // Copy the behavior of listener(commandHandler)
    test.list.forEach((element) {
      commHandlerSim(controller, element);
    });

    // ----- Decryption -----
    cat = "./testdata/keypair1/cat.pub";
    fox = "./testdata/keypair2/fox";

    AesGcmChunk decrypt = decryptSetup();
    await decrypt.decrypt(controller.stream, cat, fox);

    test.close();
    controller.close();
    // ----- Decryption End -----

    // TODO: Use checksum to check if the input and the output is the same
  });
}

void commHandlerSim(StreamController<Message> controller, Uint8List element) {
  // Header
  int size = bytesToUint32(element);
  int errorCode = element[4];
  int commandCode = element[5];
  Uint8List data = Uint8List(0);
  // print(element.sublist(0, 6));
  if (errorCode != 0) {
    // if errorCode is not in Error class, then return unknown Error
    if (!errorsList.asMap().containsKey(errorCode)) {
      errorCode = UnknownCodeError.code;
    }
  }
  if (size != 0) {
    // Data
    data = element.sublist(6);
    // print(data);
  }
  Message msg =
      Message(size, errorsList[errorCode], commandsList[commandCode], data);
  controller.add(msg);
}
