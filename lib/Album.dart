import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'client.dart';

class Album extends StatefulWidget {
  Client? client;

  Album({required this.client});

  // Contacts

  @override
  _Album createState() => _Album(client);
}

class _Album extends State<Album> {
  Client? client;

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
            return Container(
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 20),
              // child: Text('$index'),
              child: Text(files.keys.toList()[index]),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 70, vertical: 40),
            width: double.infinity,
            child: ElevatedButton(
              child: Text('Select Images', style: TextStyle(fontSize: 24)),
              onPressed: getImage,
            ),
          ),
        ),
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
        setState(() {});
      }
    } else {
      // User canceled the picker
    }
    // files.forEach((k,v) => print('${k}: ${v}'));
  }
}
