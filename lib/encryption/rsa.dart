
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:mobile_app/client.dart';
import "package:pointycastle/export.dart";


/// Encrypt the given [message] using the given RSA [publicKey].
/// Sign with the [privateKey]
/// We copied this from CryptoUtil
/// https://github.com/Ephenodrom/Dart-Basic-Utils#cryptoutils
List? rsaEncrypt(Uint8List data, RSAPublicKey publicKey, RSAPrivateKey privateKey) {
  try{
    RSAEngine cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    Uint8List encryptData = cipher.process(data);

    // sign the symmetric encryption key
    Uint8List dataSignature = CryptoUtils.rsaSign(privateKey, encryptData);
    return [encryptData, dataSignature];


  }catch(e){
    logger.d("Error in rsaEncrypt()")
    return null;
  }

}
