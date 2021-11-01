import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

const int rsaKeySize = 4096;

typedef EncryptSignNative = Int8 Function(Pointer<Utf8> pubFileName,
    Pointer<Utf8> privFileName, Pointer<_SymKeyExt> outPtr, Int32 count);
typedef EncryptSignFunc = int Function(Pointer<Utf8> pubFileName,
    Pointer<Utf8> privFileName, Pointer<_SymKeyExt> outPtr, int count);

typedef DecryptVerifyNative = Int8 Function(Pointer<Utf8> txPubKeyName,
    Pointer<Utf8> rxPrivKeyName, Pointer<_SymKeyExt> outPtr);
typedef DecryptVerifyFunc = int Function(Pointer<Utf8> txPubKeyName,
    Pointer<Utf8> rxPrivKeyName, Pointer<_SymKeyExt> outPtr);

var libraryPath =
    p.join(Directory.current.path, "lib", "encryption", "librsa", "librsa.a");
final dylib = DynamicLibrary.open(libraryPath);

final EncryptSignFunc _encryptSign = dylib
    .lookupFunction<EncryptSignNative, EncryptSignFunc>("EncryptSignExport");
final DecryptVerifyFunc _decryptVerify =
    dylib.lookupFunction<DecryptVerifyNative, DecryptVerifyFunc>(
        "DecryptVerifyExport");

class _SymKeyExt extends Struct {
  external Pointer<Uint8> key;
  @Int32()
  external int keyLength;

  external Pointer<Uint8> encryptedKey;
  @Int32()
  external int encryptedKeyLength;

  external Pointer<Uint8> signature;
  @Int32()
  external int signatureLength;
}

// SymKey class stores a symmetric key.
class SymKey {
  // Plaintext key
  Uint8List _key;

  Uint8List get key => this._key;

  // Encrypted key
  Uint8List _encryptedKey;

  Uint8List get encryptedKey => this._encryptedKey;

  // Signature
  Uint8List _signature;

  Uint8List get signature => this._signature;

  SymKey(this._key, this._encryptedKey, this._signature);
}

// EncryptSign class create symmetric keys, encrypt/sign it then save it in keys
class EncryptSign {
  List<SymKey> _keys = List<SymKey>.empty(growable: true);

  List<SymKey> get keys => this._keys;

  final String rxPubN;
  final String txKeysN;

  Pointer<Utf8>? _pubFileN;
  Pointer<Utf8>? _privFileN;

  Pointer<_SymKeyExt>? _keyArrPtr;
  int _keyArrLength = 0;

  // rxPubN: File name of receiver's public key. E.g. "/foo/bar/cat.pub"
  // txKeysN: Public/Private key file name without extensions. E.g. "/foo/bar/key", "./bob"
  EncryptSign(this.rxPubN, this.txKeysN);

  // Create {count} symmetric keys and encrypt/sign them and save it at {this._keys}.
  // Returns the number of keys created, or a negative number to indicate errors
  // when keys cannot not be opened/parsed etc.
  //
  // You can generate additional keys (this will discard old keys), but when
  // you're creating keys for a different pub key, you have to close() it
  // and initialize this class again.
  //
  // count: Total number of keys to create. If n < count keys are created, return created keys
  int createSymKeys(int count) {
    _freeMem();

    String privFileName = this.txKeysN + ".priv";
    bool isPub = File(this.rxPubN).existsSync();
    bool isPriv = File(privFileName).existsSync();

    // If receiver's public does not exist, throw error and return null
    if (!isPub) {
      // Error handling
      return 0;
    }

    // If keys don't exist, create it and proceed
    if (!isPriv) {
      print("Creating key");
      final pair = CryptoUtils.generateRSAKeyPair(keySize: rsaKeySize);

      // Examine the generated key-pair
      final rsaPublic = pair.publicKey as RSAPublicKey;
      final rsaPrivate = pair.privateKey as RSAPrivateKey;

      // Write generated keys
      File(txKeysN + ".pub").writeAsStringSync(
          CryptoUtils.encodeRSAPublicKeyToPemPkcs1(rsaPublic));
      File(privFileName).writeAsStringSync(
          CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(rsaPrivate));
    }

    // Allocate memory
    this._keyArrPtr = malloc<_SymKeyExt>(sizeOf<_SymKeyExt>() * count);

    // If this function was called to generate additional keys,
    // file names are already allocated.
    if (this._pubFileN == null) {
      this._pubFileN = this.rxPubN.toNativeUtf8();
    }
    if (this._privFileN == null) {
      this._privFileN = privFileName.toNativeUtf8();
    }

    int res = _encryptSign(
        this._pubFileN!, this._privFileN!, this._keyArrPtr!, count);
    if (res <= 0) {
      // Error handling
      print("Error while reading/parsing keys");
      _freeMem();
      return 0;
    }

    if (res != count) {
      // Some keys are not created correctly
      print("Created $res keys instead of $count. Continuing...");
    }

    this._keyArrLength = res;
    for (int i = 0; i < res; i++) {
      _SymKeyExt curr = this._keyArrPtr!.elementAt(i).ref;
      this._keys.add(SymKey(
          curr.key.asTypedList(curr.keyLength),
          curr.encryptedKey.asTypedList(curr.encryptedKeyLength),
          curr.signature.asTypedList(curr.signatureLength)));
    }

    return res;
  }

  // Release allocated memory for keys
  void _freeMem() {
    if (this._keyArrPtr != null) {
      for (int i = 0; i < this._keyArrLength; i++) {
        _SymKeyExt curr = this._keyArrPtr!.elementAt(i).ref;

        malloc.free(curr.key);
        malloc.free(curr.encryptedKey);
        malloc.free(curr.signature);
      }
      malloc.free(this._keyArrPtr!);
      this._keyArrPtr = null;
      this._keyArrLength = 0;
      this._keys = List<SymKey>.empty(growable: true);
    }
  }

  // Release all allocated memory
  void close() {
    if (this._pubFileN != null) {
      malloc.free(this._pubFileN!);
      this._pubFileN = null;
    }
    if (this._privFileN != null) {
      malloc.free(this._privFileN!);
      this._privFileN = null;
    }
    _freeMem();
  }
}

// DecryptVerify class will retrieve symmetric key from encrypted data and signature and store it in key
class DecryptVerify {
  Uint8List _key = Uint8List(0);

  Uint8List get key => this._key;

  final String txPubN;
  final String rxKeysN;

  Pointer<Utf8>? _pubFileN;
  Pointer<Utf8>? _privFileN;

  Pointer<_SymKeyExt>? _keyPtr;

  // txPubN: File name of sender's public key. E.g. "/foo/bar/dog.pub"
  // rxKeysN: Public/Private key file name without extensions. E.g. "/foo/bar/key", "./bob"
  DecryptVerify(this.txPubN, this.rxKeysN);

  // Retrieves a symmetric key from {encryptedData}, verify with {signature},
  // then save it in {this._key}.
  // Returns a negative error code or 0 if the operation was successful.
  //
  // encryptedData: Encrypted symmetric key in bytes
  // signature: Signature of the symmetric key in bytes
  int getSymKey(Uint8List encryptedData, Uint8List signature) {
    _freeMem();

    String privFileName = this.rxKeysN + ".priv";
    bool isPub = File(this.txPubN).existsSync();
    bool isPriv = File(privFileName).existsSync();

    if (!isPub) {
      // Error handling
      print("public key not found");
      return -5;
    } else if (!isPriv) {
      print("private key not found");
      return -6;
    }

    // Allocate memory for _SymKeyExt structure
    this._keyPtr = malloc<_SymKeyExt>(sizeOf<_SymKeyExt>());
    // Allocate memory for C uchar array of encryptedData
    this._keyPtr!.ref.encryptedKey = malloc<Uint8>(encryptedData.length);
    // Allocate memory for C uchar array of signature
    this._keyPtr!.ref.signature = malloc<Uint8>(signature.length);

    // Allocate file names to C heap
    if (this._pubFileN == null) {
      this._pubFileN = this.txPubN.toNativeUtf8();
    }
    if (this._privFileN == null) {
      this._privFileN = privFileName.toNativeUtf8();
    }

    // Copy dart list to C array
    uint8listToArr(this._keyPtr!.ref.encryptedKey, encryptedData);
    uint8listToArr(this._keyPtr!.ref.signature, signature);

    this._keyPtr!.ref.encryptedKeyLength = encryptedData.length;
    this._keyPtr!.ref.signatureLength = signature.length;

    int res = _decryptVerify(this._pubFileN!, this._privFileN!, this._keyPtr!);
    if (res == 0) {
      this._key =
          this._keyPtr!.ref.key.asTypedList(this._keyPtr!.ref.keyLength);
      return 0;
    } else if (res == -1) {
      print("Error caused while opening a file");
    } else if (res == -2) {
      print("Error cause while parsing a key");
    } else if (res == -3) {
      print("Error cause while decrypting");
    } else if (res == -4) {
      print("Could not validate the data");
    }
    return res;
  }

  // Release allocated memory for the key
  void _freeMem() {
    if (this._keyPtr != null) {
      malloc.free(this._keyPtr!.ref.encryptedKey);
      malloc.free(this._keyPtr!.ref.signature);
      malloc.free(this._keyPtr!.ref.key);
      malloc.free(this._keyPtr!);
      this._keyPtr = null;
      this._key = Uint8List(0);
    }
  }

  // Release all allocated memory
  void close() {
    if (this._pubFileN != null) {
      malloc.free(this._pubFileN!);
      this._pubFileN = null;
    }
    if (this._privFileN != null) {
      malloc.free(this._privFileN!);
      this._privFileN = null;
    }
    _freeMem();
  }
}

// A helper function to copy dart Uint8List to C uchar arr
void uint8listToArr(Pointer<Uint8> ptr, Uint8List li) {
  for (int i = 0; i < li.length; i++) {
    ptr[i] = li[i];
  }
}
