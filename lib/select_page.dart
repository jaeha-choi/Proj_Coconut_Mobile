import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// import 'package:path_provider/path_provider.dart';
import 'util.dart';

class SelectPage extends StatefulWidget {
  SelectPage({Key? key, required this.title}) : super(key: key);

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
  // String tempPath;
  late List<File> filePath;
  final files = new Map();
  final myController = TextEditingController();
  late RawSocket socket;


  // getFile gets any types of files (single or multiple) from devices (android and iPhone)
  void getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);

    if (result != null) {
      filePath = result.paths.map((path) => File(path!)).toList();
      String localName;
      String key;
      for (int i = 0; i < filePath.length; i++) {
        localName = filePath[i].path;
        key = localName.substring(localName.lastIndexOf("/") + 1, localName.length);

        // no collision from key
        files.putIfAbsent(key, () => filePath[i]);
        setState(() {});
      }
    } else {
      // User canceled the picker
    }
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      filePath = result.paths.map((path) => File(path!)).toList();
      String localName;
      String key;

      for (int i = 0; i < filePath.length; i++) {
        localName = filePath[i].path;
        key = localName.substring(localName.lastIndexOf("/") + 1, localName.length);

        // no collision from key
        files.putIfAbsent(key, () => filePath[i]);
        setState(() {});
      }
    } else {
      // User canceled the picker
    }
    // files.forEach((k,v) => print('${k}: ${v}'));
  }


  void connectsToSocket() async {
    try {
      socket = await RawSocket.connect('143.198.234.58', 1234);
    } on SocketException catch (e) {
      print(e);
    }
  }

  Future sendFile() async {
    /*
    :return: Received data in bytes. None if not all bytes were received.
     */
    connects_to_socket();
    print(socket);
    print('connected');

    // serverSaveNames are file names ex) ['cat.jpeg', 'dog.png', 'eng 101.doc']
    // List<String> serverSaveNames = [];
    // String localName;

    writeFileBin(socket, files);
  }

  // final Map<String, File> files = {};

  Future writeFileBin(RawSocket conn, Map files) async {
    // files.forEach((k,v) => writeString(conn, k) );
    // files.forEach((k,v) =>  writeBinary(conn, v) );

    for (var k in files.keys) {
      writeString(conn, k);
      writeBinary(conn, files[k]);
    }
  }

  @override
  Widget build(BuildContext context) {
    int itemCount;
    connects_to_socket();

    if (files == null) {
      itemCount = 0;
    } else {
      itemCount = files.length;
    }

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.brown,
        ),
        child: Column(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          children: <Widget>[
            itemCount > 0
                ? Padding(
                    padding: EdgeInsets.fromLTRB(0, 30, 200, 5),
                    child: Text(
                      'connect_ME',
                      style: TextStyle(fontSize: 30),
                    ))
                : Spacer(),
            Container(
              height: 300,
              width: 400,
              child: itemCount > 0
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: itemCount,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                            //TODO need to implement delete file from file list
                            title: Text(files.keys.toList()[index]));
                      },
                    )
                  : Center(
                      child: Text(
                      'connect_ME',
                      style: TextStyle(fontSize: 11),
                    )),
            ),
            // Center(
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //       children: <Widget>[
            //         // InkWell(
            //         //   child: Text(
            //         //     "Your Unique ID (Tap to copy)",
            //         //     style: TextStyle(fontSize: 17),
            //         //   ),
            //         //   onTap: () {
            //         //     // Copy uuid to clipboard
            //         //     Clipboard.setData(new ClipboardData(text: uid));
            //         //   },
            //         // ),
            //         // Container(
            //         //     child: Padding(
            //         //         padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
            //         //         child: InkWell(
            //         //           child: Text(
            //         //             uid,
            //         //             style: TextStyle(fontSize: 17, backgroundColor: Colors.white12),
            //         //           ),
            //         //           onTap: () {
            //         //             // Copy uuid to clipboard
            //         //             Clipboard.setData(new ClipboardData(text: uid));
            //         //           },
            //         //         ))),
            //         // Padding(
            //         //   padding: EdgeInsets.all(9),
            //         //   child: SizedBox(
            //         //     width: 300.0,
            //         //     height: 80.0,
            //         //     child: TextField(
            //         //       controller: myController,
            //         //       obscureText: false,
            //         //       decoration: InputDecoration(
            //         //         border: OutlineInputBorder(
            //         //           borderRadius: BorderRadius.all(
            //         //             const Radius.circular(12.0),
            //         //           ),
            //         //         ),
            //         //         labelText: "Receiver Unique ID",
            //         //         labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
            //         //       ),
            //         //     ),
            //         //   ),
            //         // )
            //       ],
            //     )),

            Center(
                child: Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // Spacer(),
                  ElevatedButton(
                    child: Text("Select Files"),
                    onPressed: getFile,
                    style: ElevatedButton.styleFrom(
                        primary: Colors.white12,
                        textStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    child: Text("Select Images"),
                    onPressed: getImage,
                    style: ElevatedButton.styleFrom(
                        primary: Colors.white12,
                        textStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )),
            ElevatedButton(
              child: Text("Send File"),
              onPressed: sendFile,
              style: ElevatedButton.styleFrom(
                  primary: Colors.purple, textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            Spacer(),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
