import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

const int rsaKeySize = 4096;
const int bufferSize = 4096;

class Message {
  int size;
  int errorCode;
  Uint8List data;

  Message({
    required int size,
    required int errorCode,
    required Uint8List data,
  })  : size = size,
        errorCode = errorCode,
        data = data;
}

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

Future<Message> readBytes(StreamIterator streamIterator) async {
  int size = -1;
  int errorCode = 255; // TODO: update to actual "unknown error" error code
  Uint8List data = Uint8List(0);

  try {
    // Wait for the size + error code
    bool isDataAvailable = await streamIterator.moveNext();
    if (!isDataAvailable) {
      throw new Exception("no data available from the server");
    }
    Uint8List sizeErrorCode = streamIterator.current;
    size = bytesToUint32(sizeErrorCode);
    errorCode = sizeErrorCode[4];

    // If the packets can be trimmed before received, check if the size of
    // received data matches the size of the original msg
    if (size != 0) {
      isDataAvailable = await streamIterator.moveNext();
      if (!isDataAvailable) {
        throw new Exception("no data available from the server");
      }
      data = streamIterator.current;
    }
  } catch (e) {
    logger.e("Error in readBytes: $e");
  }

  logger.i("readBytes\tSize:$size\tErrorCode:$errorCode\tData:$data");

  return Message(size: size, errorCode: errorCode, data: data);
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

bool writeString(IOSink writer, String msg) {
  if (msg.isEmpty) {
    logger.e("msg cannot be empty");
    return false;
  }
  try {
    Uint8List? bytes = utf8.encode(msg) as Uint8List?;
    if (bytes == null) {
      throw Exception("bytes cannot be null");
    }
    writeBytes(writer, bytes);
    return true;
  } catch (e) {
    logger.e("Error in writeString(): $e");
  }
  return false;
}

/// WriteString writes message to writer
/// length of message cannot exceed BufferSize
/// returns length of total bytes sent. Return -1 on error.
int writeBytes(IOSink writer, Uint8List bytes) {
  try {
    // Get size(uint32) of total bytes to send
    var size = uint32ToBytes(bytes.length);

    // Write any error code [uint8] to writer
    // TODO: Add actual error code, instead of just 0
    Uint8List code = Uint8List(1);
    // TODO: Double check + operator works as intended
    writer.add(size + code);

    // Write bytes to writer
    writer.add(bytes);
    // writer.flush();

    return 5 + bytes.length;
  } catch (error) {
    logger.e('Error in writeString() :$error');
    return -1;
  }
}

@deprecated
void connects_to_socket() async {
  try {
    RawSocket socket = await RawSocket.connect('143.198.234.58', 1234);
    print(socket);
  } on SocketException catch (e) {
    print(e);
  }
}
