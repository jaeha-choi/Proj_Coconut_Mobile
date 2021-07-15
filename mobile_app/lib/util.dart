import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

const int bufferSize = 4096;
String tempPath;
List<File> files;

void getFile() async {
  Directory tempDir = await getTemporaryDirectory();
  tempPath = tempDir.path;
  FilePickerResult result =
      await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);

  if (result != null) {
    files = result.paths.map((path) => File(path)).toList();
    //setState(() {}); => move to main.dart
  } else {
    // User canceled the picker
  }
}

// readString reads string from a connection
//
// returns <String, int> TODO need to replace RawSocket
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
// returns <[] bytes, error>    TODO int? or uint32?
List readNBytes(RawSocket reader, int n) {
  Uint8List data = reader.read(n);
  if (data == null) {
    return [-1, false];
  }
  return [data, true];
}

// Byte to unsigned int32
// TODO Research more (got this func from web)
int byteToUint32(Uint8List value) {
  var buffer = value.buffer;
  var byteData = new ByteData.view(buffer);
  return byteData.getUint32(0);
}
