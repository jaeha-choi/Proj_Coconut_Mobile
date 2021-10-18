import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../client.dart';

class Album extends StatefulWidget {
  Client client;

  Album({required this.client});

  // Contacts

  @override
  _Album createState() => _Album(client);
}

class _Album extends State<Album> {
  Client client;

  _Album(this.client);

  late List<File> filePath;
  final files = new Map();

  Widget build(BuildContext context) {
    int itemCount;

    if (files == null) {
      itemCount = 0;
    } else {
      itemCount = files.length;
    }

    return Scaffold(
        body: Stack(
      children: <Widget>[
        ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 1.0, horizontal: 1.0),
                  child: Card(
                    child: ListTile(
                      onTap: () {},
                      title: Text(files.keys.toList()[index]),
                    ),
                  ));
            }),
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 40.0, horizontal: 1.0),
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: Text('Select Files',
                            style: TextStyle(fontSize: 24)),
                        onPressed: getImage,
                      ),
                      ElevatedButton(
                        child: Text('Send', style: TextStyle(fontSize: 24)),
                        onPressed: () {},
                      ),
                    ])))
      ],
    ));
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      filePath = result.paths.map((path) => File(path!)).toList();
      String localName;
      String key;

      for (int i = 0; i < filePath.length; i++) {
        localName = filePath[i].path;
        key = localName.substring(
            localName.lastIndexOf("/") + 1, localName.length);

        // no collision from key
        files.putIfAbsent(key, () => filePath[i]);
        print(files);
        setState(() {});
      }
    } else {
      // User canceled the picker
    }
    // files.forEach((k,v) => print('${k}: ${v}'));
  }

// void sendFile(Map files) async {
//   for (var f in files.keys){
//     writeBinary(conn, file)
//   }
// }
}
