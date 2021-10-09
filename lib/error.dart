class Error {
  String error;
  int errorCode;

  Error({
    required error,
    required errorCode,
  })  : error = error,
        errorCode = errorCode;
}

Error noError = Error(error: 'no error', errorCode: 0);
Error unKnownCodeError =
    Error(error: 'unknown error code returned', errorCode: 1);
Error unKnownCommandError =
    Error(error: 'unknown command returned', errorCode: 2);
Error generalServerError = Error(error: 'general server error', errorCode: 3);
Error taskNotCompleteError = Error(error: 'task not complete', errorCode: 4);
Error pubKeyMismatchError = Error(error: 'public key mismatch', errorCode: 5);
Error clientNotFoundError =
    Error(error: 'client not found error', errorCode: 6);
Error receiverNotFound =
    Error(error: 'receiver is not available', errorCode: 7);
Error receiverNotAvailable =
    Error(error: 'receiver is not available', errorCode: 8);
Error noAvailableAddCodeError =
    Error(error: 'no available add code error', errorCode: 9);
Error existingConnError =
    Error(error: 'existing connection present in client struct', errorCode: 10);

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
