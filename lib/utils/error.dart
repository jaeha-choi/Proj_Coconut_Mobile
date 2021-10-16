import 'dart:typed_data';

import 'package:mobile_app/utils/util.dart';

class Error {
  String error;
  Uint8List errorCode;

  Error({
    required error,
    required errorCode,
  })  : error = error,
        errorCode = errorCode;
}

Error noError =
    Error(error: 'no error', errorCode: convertIntByte(0, Endian.big, 1));
Error unKnownCodeError = Error(
    error: 'unknown error code returned',
    errorCode: convertIntByte(1, Endian.big, 1));
Error unKnownCommandError = Error(
    error: 'unknown command returned',
    errorCode: convertIntByte(2, Endian.big, 1));
Error generalServerError = Error(
    error: 'general server error', errorCode: convertIntByte(3, Endian.big, 1));
Error taskNotCompleteError = Error(
    error: 'task not complete', errorCode: convertIntByte(4, Endian.big, 1));
Error pubKeyMismatchError = Error(
    error: 'public key mismatch', errorCode: convertIntByte(5, Endian.big, 1));
Error clientNotFoundError = Error(
    error: 'client not found error',
    errorCode: convertIntByte(6, Endian.big, 1));
Error receiverNotFound = Error(
    error: 'receiver is not available',
    errorCode: convertIntByte(7, Endian.big, 1));
Error receiverNotAvailable = Error(
    error: 'receiver is not available',
    errorCode: convertIntByte(8, Endian.big, 1));
Error noAvailableAddCodeError = Error(
    error: 'no available add code error',
    errorCode: convertIntByte(9, Endian.big, 1));
Error existingConnError = Error(
    error: 'existing connection present in client struct',
    errorCode: convertIntByte(10, Endian.big, 1));

var error = [
  noError,
  unKnownCodeError,
  unKnownCommandError,
  generalServerError,
  taskNotCompleteError,
  pubKeyMismatchError,
  clientNotFoundError,
  receiverNotFound,
  receiverNotAvailable,
  noAvailableAddCodeError,
  existingConnError
];

void main() {
  print(error.length);
}
