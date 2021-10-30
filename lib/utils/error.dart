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
const Error GeneralClientError = Error("general client error", 4);
const Error TaskNotCompleteError = Error("task not complete", 5);
const Error PubKeyMismatchError = Error("public key mismatch", 6);
const Error ClientNotFoundError = Error("client not found error", 7);
const Error ReceiverNotFound = Error("receiver was not found", 8);
const Error ReceiverNotAvailable = Error("receiver is not available", 9);
const Error NoAvailableAddCodeError = Error("no available add code error", 10);
const Error ExistingConnError =
    Error("existing connection present in client struct", 11);
const Error WritingMsgError = Error("can't write data to writer", 12);

const List<Error> errorsList = [
  NoError,
  UnknownCodeError,
  UnknownCommandError,
  GeneralServerError,
  GeneralClientError,
  TaskNotCompleteError,
  PubKeyMismatchError,
  ClientNotFoundError,
  ReceiverNotFound,
  ReceiverNotAvailable,
  NoAvailableAddCodeError,
  ExistingConnError,
  WritingMsgError
];
