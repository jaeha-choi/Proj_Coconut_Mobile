import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:mobile_app/client.dart';

import 'commands.dart';
import 'error.dart';

const int rsaKeySize = 4096;
const int bufferSize = 4096;

var logger = Logger(
  printer: PrettyPrinter(
      methodCount: 1,
      // number of method calls to be displayed
      errorMethodCount: 3,
      // number of method calls if stacktrace is provided
      lineLength: 50,
      // width of the output
      colors: true,
      // Colorful log messages
      printEmojis: true,
      // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
      ),
);

/// ----Conversions----

/// Convert integer to byte
Uint8List? convertIntToByte(value, Endian order, int bytesSize) {
  try {
    final kMaxBytes = 8;
    var bytes = Uint8List(kMaxBytes)
      ..buffer.asByteData().setInt64(0, value, order);
    List<int> intArray;
    if (order == Endian.big) {
      intArray = bytes.sublist(kMaxBytes - bytesSize, kMaxBytes).toList();
    } else {
      intArray = bytes.sublist(0, bytesSize).toList();
    }
    return Uint8List.fromList(intArray);
  } catch (e) {
    print('util convert error: $e');
  }
}

/// Convert 4 bytes to unsigned int32
int bytesToUint32(Uint8List value, [int offsetInBytes = 0]) {
  // var buffer = value.buffer;
  // var byteData = new ByteData.view(buffer, offsetInBytes, 4);
  ByteData byteData =
      ByteData.sublistView(value, offsetInBytes, offsetInBytes + 4);
  return byteData.getUint32(0);
}

/// Convert 4 bytes to unsigned int16
int bytesToUint16(Uint8List value, [int offsetInBytes = 0]) {
  // var buffer = value.buffer;
  // var byteData = new ByteData.view(buffer, offsetInBytes, 4);
  ByteData byteData =
      ByteData.sublistView(value, offsetInBytes, offsetInBytes + 2);
  return byteData.getUint16(0);
}

/// Convert unsigned in 16 to bytes
Uint8List uint16ToBytes(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

/// Convert unsigned int32 to bytes
Uint8List uint32ToBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

// // getFilePath calls getApplication Documents Directory. This comes from the path_provider package.
// // This will get whatever the common documents directory is for the platform that we are using.
// // returns path to the documents directory as a String
// Future<String> getFilePath() async {
//   Directory appDocumentsDirectory = await getApplicationDocumentsDirectory(); // 1
//   String appDocumentsPath = appDocumentsDirectory.path; // 2
//   String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3
//
//   return filePath;
// }

Future<Message> readBytes(StreamIterator<Message> iter) async {
  // Wait for the msg
  bool isDataAvailable = await iter.moveNext();
  if (!isDataAvailable) {
    // throw new Exception("no data available from the server");
    // what is Error ReceiverNotFound from Error class
    print('ohno');
    return Message(0, GeneralClientError, Init, Uint8List(0));
  }
  return iter.current;
}

// writeBinary opens file and write byte data to writer
//
// returns <total length of bytes to sent, error>
// total length of bytes = each file size
// file size cannot exceed max value of uint32
Future<List> writeBinary(RawSocket conn, File file) async {
  var sizeInByte = uint32ToBytes(await file.length());
  try {
    conn.write(sizeInByte);
    print(file.readAsBytes());
    print("reading file size (Bytes):  ${file.readAsBytes()}");
    conn.write(await file.readAsBytes());
  } catch (error) {
    logger.e("Unknown error in send_bin: $error");
    return [0, false];
  }
  return [sizeInByte, true];
}

int writeString(IOSink writer, String msg, Command command, Error error) {
  // Chang command to Uint8Lsit
  if (msg.isEmpty) {
    logger.e("msg cannot be empty");
    return -1;
  }
  return writeBytes(
      writer, Uint8List.fromList(utf8.encode(msg)), command, error);
}

/// WriteString writes message to writer
/// length of message cannot exceed BufferSize
/// returns length of total bytes sent. Return -1 on error.
int writeBytes(IOSink writer, Uint8List bytes, Command command, Error error) {
  try {
    // Get size(uint32) of total bytes to send
    Uint8List size = uint32ToBytes(bytes.length);
    // Write any error code [uint8] to writer
    Uint8List errCode = Uint8List.fromList([error.code]);
    // Get Command and change it to Uint8List
    Uint8List commandCode = convertIntToByte(command.code, Endian.big, 1)!;

    // Write bytes to writer
    writer.add(size + errCode + commandCode + bytes);
    // writer.flush();

    return 6 + bytes.length;
  } catch (error) {
    logger.e('Error in writeString() :$error');
    return -1;
  }
}

void main() {
  int s = 2;
  print(convertIntToByte(s, Endian.big, 1));
}
