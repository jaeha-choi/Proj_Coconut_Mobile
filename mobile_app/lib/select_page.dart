import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SelectPage extends StatefulWidget {
  SelectPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<StatefulWidget> createState() => _MySelectPageState();
}

class _MySelectPageState extends State<SelectPage> {

  String tempPath;
  List<File> files;

  // getFile gets any types of files (single or multiple) from devices (android and iPhone)
  void getFile() async {
    Directory tempDir = await getTemporaryDirectory();
    tempPath = tempDir.path;
    FilePickerResult result =
    await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);

    if (result != null) {
      files = result.paths.map((path) => File(path)).toList();
      print(files);
      setState(() {});
    } else {
      print("Error while getting file from user");
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            Center(
              child: Row(
                children: <Widget>[
                  ElevatedButton(child: Text("Select Files"), onPressed: getFile),
                  // ElevatedButton(
                  //   child: Text("Send Files"), onPressed: readString(reader),
                  // )
                ],
              ),
            )
          ])),
    );
  }
}
