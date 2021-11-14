import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:mobile_app/client.dart';

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

void main() async {
  // Using newClient() in this file is necessary, if you want to test without UI
  Client robin = await newClient();
  await robin.connect();
  await robin.doGetAddCode();
  await robin.disconnect();
  // await robin.getResult(command, iter)
  // Client jaeha = await newClient();
  // jaeha.connect();

  RSAPublicKey robinPub =
      CryptoUtils.rsaPublicKeyFromPemPkcs1(robin.pubKeyBlock);
  // create robin public key
  String jaehaPubStr = File('./testdata/jaehaPub.pub').readAsStringSync();

  RSAPublicKey jaehaPub = CryptoUtils.rsaPublicKeyFromPemPkcs1(jaehaPubStr);

  String fileName = "./testdata/short_txt.txt";
  ByteStream test = ByteStream();
  // await Future.delayed(Duration(minutes: 1));
  print('here');
}
