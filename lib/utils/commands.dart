class Command {
  final String string;
  final int code;

  const Command(this.string, this.code);

  String toString() {
    return string;
  }
}

const Command Init = Command("INIT", 0);
const Command Quit = Command("QUIT", 1);
const Command RequestPubKey = Command("RPUB", 2);
const Command GetPubKey = Command("GPUB", 3);
const Command RemoveAddCode = Command("RADC", 4);
const Command GetAddCode = Command("GADC", 5);
const Command EndRelay = Command("ERLY", 6);
const Command RequestRelay = Command("RELY", 7);
// GetP2PKey get public key for client you want to connect
const Command HandleRequestP2P = Command("HPTP", 8);
// RequestPTP request peer to peer ip address
const Command RequestP2P = Command("RPTP", 9);
const Command FileCommand = Command("FILE", 10);
const Command Pause = Command("PAUS", 11);
const Command Conn = Command("CONN", 12);

const List<Command> commandsList = [
  Init,
  Quit,
  RequestPubKey,
  GetPubKey,
  RemoveAddCode,
  GetAddCode,
  EndRelay,
  RequestRelay,
  HandleRequestP2P,
  RequestP2P,
  FileCommand,
  Pause,
  Conn
];
