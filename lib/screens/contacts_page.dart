import 'package:flutter/material.dart';

import '../client.dart';
import '../utils/contact_class.dart';

class Contacts extends StatefulWidget {
  Client client;

  Contacts({required this.client});

  // Contacts

  @override
  _Contacts createState() => _Contacts(client);
}

class _Contacts extends State<Contacts> {
  Client client;

  _Contacts(this.client);

  bool isOnLine = true;

  Widget build(BuildContext context) {
    // var contacts = new Map();
    String addCode = client.addCode;

    String addLabel = "Your ID: $addCode";

    bool shouldDisplay = false;

    void changeStatus() {
      isOnLine = !isOnLine;
      setState(() {});
    }

    void changeText() {
      setState(() {
        addLabel = "Your ID: $addCode";
      });
    }

    Widget buildOffLine(bool isOnLine) => ElevatedButton(
        onPressed: () async {
          await client.doGetAddCode(client);
          changeStatus();
        },
        child: Text(
          'OffLine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all(StadiumBorder()),
            backgroundColor: MaterialStateProperty.all(Colors.red),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15))));

    Widget buildOnline() => ElevatedButton(
        onPressed: () async {
          await client.doRemoveAddCode(client);
          changeStatus();
          changeText();
        },
        child: Text(
          'Online',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all(StadiumBorder()),
            backgroundColor: MaterialStateProperty.all(Colors.green),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15))));

    // int index = 0;
    List<Person> contact = [Person('Robin Seo', 'pubKey')];
    double padding = 10;
    final sidePadding =
        EdgeInsets.symmetric(horizontal: padding, vertical: padding);
    return SafeArea(
        child: Scaffold(
            body: Container(
                decoration: BoxDecoration(),
                child: Column(
                  children: <Widget>[
                    Padding(padding: sidePadding),
                    Row(
                        // mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(padding: sidePadding),
                          Text(
                            "Contacts",
                            style: TextStyle(
                                fontSize: 35, fontWeight: FontWeight.bold),
                          ),
                          Padding(padding: sidePadding),
                          Spacer(),
                          ElevatedButton(
                            child: Icon(
                              Icons.person_add,
                              // TODO need to finish implementing

                              // color: Colors.black,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black12,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(14),
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text("Add Contact"),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      Padding(padding: sidePadding),
                                      TextField(
                                        decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: 'Enter a full name'),
                                      ),
                                      Padding(padding: sidePadding),
                                      TextField(
                                        decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: 'Enter an addCode'),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('Cancel'),
                                    style: TextButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey, width: 1),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'OK'),
                                    child: const Text('OK'),
                                    style: TextButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey, width: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ]),
                    Row(
                      children: [
                        Padding(padding: sidePadding),
                        Container(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(1, 10, 1, 10),
                                child: InkWell(
                                  child: Text(
                                    addLabel,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ))),
                        ElevatedButton(
                          onPressed: () async {
                            await client.doRemoveAddCode(client);
                            await client.doGetAddCode(client);
                            changeText();
                          },
                          child: Icon(
                            Icons.refresh,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black12,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(6),
                          ),
                        ),
                        Spacer(),
                        Container(
                          child:
                              isOnLine ? buildOnline() : buildOffLine(isOnLine),
                        ),
                        Spacer()
                      ],
                    ),
                    Expanded(
                        // height: 600,
                        // width: 400,
                        child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: contact.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) return HeaderTile();
                        return PersonTile(contact[index - 1]);
                      },
                      //       shrinkWrap: true,
                      //       itemCount: itemCount,
                      //       itemBuilder: (BuildContext context, int index) {
                      //      return ListTile(
                      //         //TODO need to implement delete file from file list
                      //
                      //           title: Text(contacts.keys.toList()[index]));
                      // },
                    )),
                  ],
                ))));
  }
}
