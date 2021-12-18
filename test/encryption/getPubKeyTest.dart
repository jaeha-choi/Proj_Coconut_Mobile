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

/// Creates new [Client] and return it.
/// Returns null upon error.
Future<Client> newClientForDuncan() async {
  // Open RSA keys, if the user already got one
  final pair = CryptoUtils.generateRSAKeyPair(keySize: 4096);
  // Examine the generated key-pair
  final rsaPublic = pair.publicKey as RSAPublicKey;
  final rsaPrivate = pair.privateKey as RSAPrivateKey;

  String pubKey = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic);
  return new Client(
    serverIP: "127.0.0.1",
    serverPort: 9129,
    // conn: null,
    privKey: rsaPrivate,
    pubKeyBlock: pubKey,
    addCode: "",
    mapOfChannel: new Map<String, StreamController<Message>>(),
  );
}

void main() async {
  // Using newClient() in this file is necessary, if you want to test without UI
  Client robin = await newClient();
  await robin.connect();
  await robin.doGetAddCode();
  Client duncan = await newClientForDuncan();
  await duncan.connect();
  await duncan.doGetAddCode();
  await robin.doRequestPubKey(duncan.addCode, 'fullName');

  await Future.delayed(Duration(minutes: 1));
  // await robin.disconnect();
  print('here');
}
