import 'dart:convert';
import "package:asn1lib/asn1lib.dart";
import "package:pointycastle/export.dart";

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
}

List<int> decodePEM(String pem) {
  return base64.decode(removePemHeaderAndFooter(pem));
}
