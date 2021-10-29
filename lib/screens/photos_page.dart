import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/utils/contact_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contacts_page.dart';
import '../client.dart';
import 'package:mobile_app/screens/contacts_page.dart';

class Photos extends StatefulWidget {
  Client client;

  Photos({required this.client});

  // Contacts

  @override
  _Photos createState() => _Photos(client);
}

class _Photos extends State<Photos> {
  Client client;

  _Photos(this.client);

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
                            onPressed: () async {
                              final prefs = await SharedPreferences
                                  .getInstance();
                              List<String> spList = prefs.getStringList(
                                  'list')!;
                              List<User> friendsList =
                              spList.map((item) =>
                                  User.fromMap(json.decode(item))).toList();
                              print(spList);
                              showDialog(context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                        title: const Text("Contact List"),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: <Widget>[
                                              // TODO need to create Contact List
                                              ListView.builder(itemBuilder:)
                                              // ListView.builder(
                                              //   itemCount : friendsList.length,
                                              //   itemBuilder: (BuildContext context, int index) {
                                              //   return Container(
                                              //     child: Center(child: Text(friendsList[index].fullName),)
                                              //   );
                                              // })

                                            ],
                                          ),
                                        ),
                                      )
                              );

                              // print(friendsList);

                            },
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
