import 'package:logger/logger.dart';



class SimpleLogPrinter extends LogPrinter {
  final String className;
  SimpleLogPrinter(this.className);
  // int method_count = PrettyPrinter.printTime;


  // logger.v('You don\'t always want to see all of these');
  // logger.d('Logs a debug message');
  // logger.i('Public Function called');
  // logger.w('This might become a problem');
  // logger.e('Something has happened');
  @override
  void log(Level level, message, error, StackTrace stackTrace) {
    var color = PrettyPrinter.levelColors[level];
    var emoji = PrettyPrinter.levelEmojis[level];
    // var count = stackTrace

    println(color('$emoji $className - $message '));
  }
}