import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


const int bufferSize = 4096;


// readSize reads first 4 bytes from the reader and convert them into a uint32 value
//
// return [uint32, error (bool)]
List readSize(RawSocket reader) {
  // Read first 4 bytes for the size
  List size = readNBytes(reader, 4);
  var b = size.first;
  var err = size.last;
  print('size of file ' + b + 'error msg: ' + err);

  // convert them into a unit32value
  if (err == true) {
    return [byteToUint32(b), true];
  }
  print("Error while reading packet size");
  return [0, false];
}

// readNBytes reads up to nth byte
//
// returns <[] bytes, error>
List readNBytes(RawSocket reader, int n) {
  Uint8List data = reader.read(n); // store in file
  if (data == null) {
    print("Error while reading bytes");
    return [-1, false];
  }
  return [data, true];
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
List writeString (RawSocket writer, String msg) {
  try {
    // Convert string to byte
    // * actual information converted into byte
    var bytes = utf8.encode(msg);
    // Get size(uint32) of total bytes to send
    var size = uint32ToByte(bytes.length);
    writer.write(size + bytes);
    return [size ,true];
  } catch (error) {
    return [0 ,false];
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
    return [0,false];
  }
  return [sizeInByte,true];
}





// readString reads string from a connection
//
// returns <String, int>
List readString(RawSocket reader) {
  var size = readSize(reader).first;
  var err = readSize(reader).last;
  if (err == false) {
    print('Error while reading string size');
  }

  // ReadString always expect the size to be <= bufferSize
  if (size > bufferSize) {
    print("String size cannot be greater than " + bufferSize.toString() + ". String size: " + size);
    return ["", false];
  }

  // Read string from the packet
  String str = readNString(reader, size).first;
  err = readNBytes(reader, size).last;
  if (err == false) {
    print("Error while reading string");
    return ["", false];
  }
  print(str);
  return [str, true];
}

// readNString reads up to nth character. Maximum length should not exceed bufferSize.
// return string, error
List readNString(RawSocket reader, int n) {
  if (n > bufferSize) {
    print("n should be smaller than " + bufferSize.toString());
    return ["", false];
  }
  var buffer = readNBytes(reader, n).first;
  var err = readNBytes(reader, n).last;
  return [buffer.toString(), err];
}


