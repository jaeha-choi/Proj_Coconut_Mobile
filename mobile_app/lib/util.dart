import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const int bufferSize = 4096;

// readSize reads first 4 bytes from the reader and convert them into a uint32 value
//
// return packet size (uint32)
int readSize(RawSocket reader) {
  // Read first 4 bytes for the packet size
  Uint8List packetSize = readNBytes(reader, 4);
  print('size of file ' + byteToUint32(packetSize).toString());

  if (packetSize == null) {
    print("Error while reading packet size");
    return 0;
  }
  // convert them into a unit32value
  return byteToUint32(packetSize);
}

// readNBytes reads up to nth byte
//
// return data(8-bit unsigned integers)
Uint8List readNBytes(RawSocket reader, int n) {
  Uint8List data = reader.read(n); // read up to n byte
  if (data == null) {
    print("Error while reading bytes");
    return null;
  }
  return data;
}

// Byte to unsigned int32
int byteToUint32(Uint8List value) {
  var buffer = value.buffer;
  var byteData = new ByteData.view(buffer);
  return byteData.getUint32(0);
}

// Unsigned int32 to byte
Uint8List uint32ToByte(int value) =>
    Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

// WriteString writes message to writer
// length of message cannot exceed BufferSize
// returns <total bytes sent, error>
List writeString(RawSocket writer, String msg) {
  try {
    // Convert string to byte
    // * actual information converted into byte
    var bytes = utf8.encode(msg);
    // Get size(uint32) of total bytes to send
    var size = uint32ToByte(bytes.length);
    writer.write(size + bytes);
    return [size, true];
  } catch (error) {
    return [0, false];
  }
}

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

// writeBinary opens file and write byte data to writer
//
// returns <total length of bytes to sent, error>
// total length of bytes = each file size
// file size cannot exceed max value of uint32
Future<List> writeBinary(RawSocket conn, File file) async {
  var sizeInByte = uint32ToByte(await file.length());
  try {
    conn.write(sizeInByte);
    print(file.readAsBytes());
    print("reading file size (Bytes):  ${file.readAsBytes()}");
    conn.write(await file.readAsBytes());
  } catch (error) {
    print("Unknown error in send_bin" + error);
    return [0, false];
  }
  return [sizeInByte, true];
}

// readString reads string from a connection
//
// returns <String, status>
List readString(RawSocket reader) {
  String string = "";
  try {
    int size = readSize(reader);
    if (size == 0) {
      print('Error while reading size');
      return [string, false];
    }
    // ReadString always expect the size to be <= bufferSize
    if (size > bufferSize) {
      print("String size cannot be greater than " +
          bufferSize.toString() +
          ". String size: " +
          size.toString());
      return ["", false];
    } else {
      // Read string from the packet
      Uint8List data = reader.read(size);
      string = utf8.decode(data);
      print(string);

      // // if the above else statement doesn't work. Try to uncomment the line below and try it
      // string = utf8.decode(readNString(reader, size).first);
      // var err = readNBytes(reader, size).last;
      // if (err == false) {
      //   print("Error while reading string");
      //   return ["", false];
      // }
    }
  } catch (error) {
    print("Unknown error in readString");
    return [string, false];
  }
  return [string, true];
}

// readNString reads up to nth character. Maximum length should not exceed bufferSize.
// return [Uint8List, status]
List readNString(RawSocket reader, int n) {
  if (n > bufferSize) {
    print("n should be smaller than " + bufferSize.toString());
    return ["", false];
  }
  Uint8List buffer = readNBytes(reader, n);
  return [buffer, true];
}
