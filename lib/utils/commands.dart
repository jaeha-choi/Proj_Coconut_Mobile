const String Quit = "QUIT";
const String RequestRelay = "RELY";
const String EndRelay = "ERLY";
const String GetAddCode = "GADC";
const String RemoveAddCode = "RADC";
const String GetPubKey = "GPUB";
const String RequestPubKey = "RPUB";

class Command {
  String command;

  Command({
    required command,
  }) : command = command;
}

Command addCodeCommand = Command(command: 'GADC');

String command(name) {
  return name;
}
