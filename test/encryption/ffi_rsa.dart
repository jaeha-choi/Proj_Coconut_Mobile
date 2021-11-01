import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/encryption/ffi_rsa.dart';

void main() {
  test("rsa decryption and verification", () {
    // Cat receives key from Dog
    Uint8List data =
        File("./testdata/encryption/decryption_test_data").readAsBytesSync();
    Uint8List sig =
        File("./testdata/encryption/decryption_test_sig").readAsBytesSync();

    DecryptVerify dv =
        DecryptVerify("./testdata/dog.pub", "./testdata/keypair1/cat");
    int res = dv.getSymKey(data, sig);
    if (res != 0) {
      fail("returned error code: $res");
    }
    Uint8List expected = Uint8List.fromList([
      124,
      149,
      91,
      61,
      159,
      249,
      188,
      40,
      139,
      160,
      78,
      249,
      22,
      192,
      130,
      68,
      203,
      164,
      34,
      89,
      86,
      81,
      111,
      158,
      183,
      195,
      254,
      104,
      54,
      247,
      145,
      173
    ]);

    expect(dv.key, expected);

    dv.close();
  });

  test("rsa encryption and signature", () {
    // Cat generates key for Dog
    EncryptSign es =
        EncryptSign("./testdata/dog.pub", "./testdata/keypair1/cat");
    int res = es.createSymKeys(1);
    if (res != 1) {
      fail("returned error code: $res");
    }

    // Accessing data
    // print(es.keys[0].key);
    // print(es.keys[0].encryptedKey);
    // print(es.keys[0].signature);

    expect(es.keys[0].key.length, 32);
    expect(es.keys[0].encryptedKey.length, 512);
    expect(es.keys[0].signature.length, 512);

    es.close();
  });
}
