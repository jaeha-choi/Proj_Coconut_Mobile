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
const Command GetP2PKey = Command("GKEY", 8);
// RequestPTP request peer to peer ip address
const Command RequestPTP = Command("RPTP", 9);
// HolePunchPING init command for p2p connection
const Command GetLocalIP = Command("GLIP", 10);
// HolePunchPONG init reply to "PING" command
const Command HolePunchPING = Command("PING", 11);
const Command HolePunchPONG = Command("PONG", 12);
const Command FileCommand = Command("FILE", 13);

const List<Command> commandsList = [
  Init,
  Quit,
  RequestPubKey,
  GetPubKey,
  RemoveAddCode,
  GetAddCode,
  EndRelay,
  RequestRelay,
  GetP2PKey,
  RequestPTP,
  GetLocalIP,
  HolePunchPING,
  HolePunchPONG,
  FileCommand
];