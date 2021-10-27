class Error {
  final String string;
  final int code;

  const Error(this.string, this.code);

  String toString() {
    return this.string;
  }
}

const Error NoError = Error("no error", 0);
const Error UnknownCodeError = Error("unknown error code returned", 1);
const Error UnknownCommandError = Error("unknown command returned", 2);
const Error GeneralServerError = Error("general server error", 3);
const Error TaskNotCompleteError = Error("task not complete", 4);
const Error PubKeyMismatchError = Error("public key mismatch", 5);
const Error ClientNotFoundError = Error("client not found error", 6);
const Error ReceiverNotFound = Error("receiver was not found", 7);
const Error ReceiverNotAvailable = Error("receiver is not available", 8);
const Error NoAvailableAddCodeError = Error("no available add code error", 9);
const Error ExistingConnError =
    Error("existing connection present in client struct", 10);

const List<Error> errorsList = [
  NoError,
  UnknownCodeError,
  UnknownCommandError,
  GeneralServerError,
  TaskNotCompleteError,
  PubKeyMismatchError,
  ClientNotFoundError,
  ReceiverNotFound,
  ReceiverNotAvailable,
  NoAvailableAddCodeError,
  ExistingConnError
];
