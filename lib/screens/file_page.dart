import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../client.dart';

class SelectFile extends StatefulWidget {
  Client? client;

  SelectFile({required this.client});

  // Contacts

  @override
  _SelectFile createState() => _SelectFile(client);
}

class _SelectFile extends State<SelectFile> {
  Client? client;

  _SelectFile(this.client);

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
                        onPressed: getFile,
                      ),
                      ElevatedButton(
                        child: Text('Send', style: TextStyle(fontSize: 24)),
                        onPressed: () {},
                      ),
                    ])))
      ],
    ));
  }

  // getFile gets any types of files (single or multiple) from devices (android and iPhone)
  Future getFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any);

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
  }
}
