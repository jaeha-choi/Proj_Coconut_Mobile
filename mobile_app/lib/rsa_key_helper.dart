import 'dart:convert';
import "package:asn1lib/asn1lib.dart";
import 'package:logger/logger.dart';
import "package:pointycastle/export.dart";
import 'logger.dart';
import 'dart:math';
import 'dart:typed_data';

final logger = Logger(printer: SimpleLogPrinter('rsa_key_helper.dart'));

// Generating RSA (Asymmetric encryption)
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 4096}) {
  // Create an RSA key generator and initialize it

  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom));

  // Use the generator
  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types
  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

// SecureRandom (Fortuna)
SecureRandom exampleSecureRandom() {
  final secureRandom = FortunaRandom();

  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  return secureRandom;
}

// https://medium.com/flutter-community/asymmetric-key-generation-in-flutter-ad2b912f3309
String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
  var topLevel = new ASN1Sequence();

  var version = ASN1Integer(BigInt.from(0));
  var modulus = ASN1Integer(privateKey.n);
  var publicExponent = ASN1Integer(privateKey.exponent);
  var privateExponent = ASN1Integer(privateKey.d);
  var p = ASN1Integer(privateKey.p);
  var q = ASN1Integer(privateKey.q);
  var dP = privateKey.d % (privateKey.p - BigInt.from(1));
  var exp1 = ASN1Integer(dP);
  var dQ = privateKey.d % (privateKey.q - BigInt.from(1));
  var exp2 = ASN1Integer(dQ);
  var iQ = privateKey.q.modInverse(privateKey.p);
  var co = ASN1Integer(iQ);

  topLevel.add(version);
  topLevel.add(modulus);
  topLevel.add(publicExponent);
  topLevel.add(privateExponent);
  topLevel.add(p);
  topLevel.add(q);
  topLevel.add(exp1);
  topLevel.add(exp2);
  topLevel.add(co);

  var dataBase64 = base64.encode(topLevel.encodedBytes);

  return """-----BEGIN RSA PRIVATE KEY-----\r\n$dataBase64\r\n-----END RSA PRIVATE KEY-----""";
}

/// https://github.com/Vanethos/flutter_rsa_generator_example/blob/64eb00b00d85f122c7e94f7c17bcdbe3a0450d59/lib/utils/rsa_key_helper.dart#L192
/// https://medium.com/flutter-community/asymmetric-key-generation-in-flutter-ad2b912f3309
String removePemHeaderAndFooter(String pem) {
  var startsWith = [
    "-----BEGIN PUBLIC KEY-----",
    "-----BEGIN RSA PRIVATE KEY-----",
    "-----BEGIN RSA PUBLIC KEY-----",
    "-----BEGIN PRIVATE KEY-----",
    "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
    "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
  ];
  var endsWith = [
    "-----END PUBLIC KEY-----",
    "-----END PRIVATE KEY-----",
    "-----END RSA PRIVATE KEY-----",
    "-----END RSA PUBLIC KEY-----",
    "-----END PGP PUBLIC KEY BLOCK-----",
    "-----END PGP PRIVATE KEY BLOCK-----",
  ];
  bool isOpenPgp = pem.indexOf('BEGIN PGP') != -1;

  pem = pem.replaceAll(' ', '');
  pem = pem.replaceAll('\n', '');
  pem = pem.replaceAll('\r', '');

  for (var s in startsWith) {
    s = s.replaceAll(' ', '');
    if (pem.startsWith(s)) {
      pem = pem.substring(s.length);
    }
  }

  for (var s in endsWith) {
    s = s.replaceAll(' ', '');
    if (pem.endsWith(s)) {
      pem = pem.substring(0, pem.length - s.length);
    }
  }

  if (isOpenPgp) {
    var index = pem.indexOf('\r\n');
    pem = pem.substring(0, index);
  }

  return pem;
}

/// Decode Public key from PEM Format
///
/// Given a base64 encoded PEM [String] with correct headers and footers, return a
/// [RSAPublicKey]
///
/// *PKCS1*
/// RSAPublicKey ::= SEQUENCE {
///    modulus           INTEGER,  -- n
///    publicExponent    INTEGER   -- e
/// }
///
/// *PKCS8*
/// PublicKeyInfo ::= SEQUENCE {
///   algorithm       AlgorithmIdentifier,
///   PublicKey       BIT STRING
/// }
///
/// AlgorithmIdentifier ::= SEQUENCE {
///   algorithm       OBJECT IDENTIFIER,
///   parameters      ANY DEFINED BY algorithm OPTIONAL
/// }
///
RSAPublicKey parsePublicKeyFromPem(pemString) {
  List<int> publicKeyDER = decodePEM(pemString);
  var asn1Parser = new ASN1Parser(publicKeyDER);
  var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  var modulus, exponent;
  // Depending on the first element type, we either have PKCS1 or 2
  if (topLevelSeq.elements[0].runtimeType == ASN1Integer) {
    modulus = topLevelSeq.elements[0] as ASN1Integer;
    exponent = topLevelSeq.elements[1] as ASN1Integer;
  } else {
    var publicKeyBitString = topLevelSeq.elements[1];

    var publicKeyAsn = new ASN1Parser(publicKeyBitString.contentBytes());
    ASN1Sequence publicKeySeq = publicKeyAsn.nextObject();
    modulus = publicKeySeq.elements[0] as ASN1Integer;
    exponent = publicKeySeq.elements[1] as ASN1Integer;
  }

  RSAPublicKey rsaPublicKey =
      RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);

  return rsaPublicKey;
}

/// Decode Private key from PEM Format
/// Given a base64 encoded PEM [String] with correct headers and footers, return a
/// [RSAPrivateKey]
RSAPrivateKey parsePrivateKeyFromPem(pemString) {
  try {
    List<int> privateKeyDER = decodePEM(pemString);
    var asn1Parser = new ASN1Parser(privateKeyDER);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    var modulus, privateExponent, p, q;
    // Depending on the number of elements, we will either use PKCS1 or PKCS8
    if (topLevelSeq.elements.length == 3) {
      var privateKey = topLevelSeq.elements[2];

      asn1Parser = new ASN1Parser(privateKey.contentBytes());
      var pkSeq = asn1Parser.nextObject() as ASN1Sequence;

      modulus = pkSeq.elements[1] as ASN1Integer;
      privateExponent = pkSeq.elements[3] as ASN1Integer;
      p = pkSeq.elements[4] as ASN1Integer;
      q = pkSeq.elements[5] as ASN1Integer;
    } else {
      modulus = topLevelSeq.elements[1] as ASN1Integer;
      privateExponent = topLevelSeq.elements[3] as ASN1Integer;
      p = topLevelSeq.elements[4] as ASN1Integer;
      q = topLevelSeq.elements[5] as ASN1Integer;
    }

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
        modulus.valueAsBigInteger,
        privateExponent.valueAsBigInteger,
        p.valueAsBigInteger,
        q.valueAsBigInteger);

    return rsaPrivateKey;
  } catch (e) {
    logger.d("ERROR in RSAPrivateKey parsePrivateKeyFromPem(pemString): $e");
  }
}

List<int> decodePEM(String pem) {
  return base64.decode(removePemHeaderAndFooter(pem));
}
