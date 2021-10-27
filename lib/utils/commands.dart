class Command {
  final String string;
  final int code;

  const Command(this.string, this.code);

  String toString() {
    return string;
  }
}

const Command Init = Command("INIT", 0);
const Command RequestPubKey = Command("RPUB", 1);
const Command GetPubKey = Command("GPUB", 2);
const Command RemoveAddCode = Command("RADC", 3);
const Command GetAddCode = Command("GADC", 4);
const Command EndRelay = Command("ERLY", 5);
const Command RequestRelay = Command("RELY", 6);
const Command Quit = Command("QUIT", 7);

const List<Command> commandsList = [
  Init,
  RequestPubKey,
  GetPubKey,
  RemoveAddCode,
  GetAddCode,
  EndRelay,
  RequestRelay,
  Quit
];