import 'package:flutter/material.dart';

import '../client.dart';
import '../utils/contact_class.dart';

enum ButtonState { init, loading, done }

class Contacts extends StatefulWidget {
  Client client;

  Contacts({required this.client});

  // Contacts

  @override
  _Contacts createState() => _Contacts(client);
}

class _Contacts extends State<Contacts> {
  ButtonState state = ButtonState.init;

  Client client;

  _Contacts(this.client);

  bool notReceiving = false;

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool isDone = state == ButtonState.done;
    bool isOnLine = state == ButtonState.init;

    // var contacts = new Map();
    String addCode = client.addCode;

    bool shouldDisplay = false;

    void changeStatus() {
      isOnLine = !isOnLine;
      setState(() {});
    }

    void changeText() {
      setState(() {
        addCode = addCode;
      });
    }

    Widget buildOffLine(bool isOnLine) => ElevatedButton(
        onPressed: () async {
          setState(() => state = ButtonState.loading);
          await Future.delayed(Duration(seconds: 2));
          await client.doGetAddCode(client);
          changeStatus();
          setState(() => state = ButtonState.init);
        },
        child: Text(
          'Tap to go Online',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all(StadiumBorder()),
            backgroundColor: MaterialStateProperty.all(Colors.red),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15))));

    Widget buildOnline() => ElevatedButton(
        onPressed: () async {
          await client.doRemoveAddCode(client);
          setState(() => state = ButtonState.loading);
          await Future.delayed(Duration(seconds: 2));
          changeStatus();
          changeText();
          setState(() => state = ButtonState.done);
        },
        child: Text(
          'Online',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all(StadiumBorder()),
            backgroundColor: MaterialStateProperty.all(Colors.green),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15))));

    Widget loading(bool isDone) {
      return Container(
        child: isDone ? buildOffLine(isOnLine) : CircularProgressIndicator(),
      );
    }

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
                          Container(
                              child:
                                  isOnLine ? buildOnline() : loading(isDone)),
                          Padding(padding: sidePadding),
                        ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: sidePadding),
                        // Spacer(),

                        ElevatedButton(
                          child: Icon(
                            Icons.person_add,
                            size: 35,
                            // TODO need to finish implementing
                            // color: Colors.black,
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.black54,
                            fixedSize: Size(size.width - 50, 45),
                            shape: StadiumBorder(),
                          ),
                          // OutlinedButton.styleFrom(
                          //   backgroundColor: Colors.black12,
                          //   shape: RoundedRectangleBorder(),
                          //   padding: EdgeInsets.all(14),

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
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK'),
                                  style: TextButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(padding: sidePadding),
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
                    Container(
                        // margin:  const EdgeInsets.all(15.0),
                        // padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(children: [
                          Column(children: [
                            Row(
                              children: [
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10)),
                                Text("ADD Code",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                //TODO Add space

                                ElevatedButton(
                                  onPressed: () async {
                                    if (isOnLine && !notReceiving) {
                                      notReceiving = false;
                                      await client.doRemoveAddCode(client);
                                      await client.doGetAddCode(client);
                                      changeText();
                                    }
                                    if (isOnLine && notReceiving) {
                                      notReceiving = false;
                                      await client.doGetAddCode(client);
                                      changeText();
                                    }
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
                                ElevatedButton(
                                  onPressed: () async {
                                    if (isOnLine &&
                                        !notReceiving &&
                                        client.addCode.length == 6) {
                                      notReceiving = true;
                                      await client.doRemoveAddCode(client);
                                      changeText();
                                    }
                                  },
                                  child: Icon(
                                    Icons.close,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.black12,
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(6),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 50, vertical: 10)),
                                Text(
                                  client.addCode,
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ]),
                        ]))
                  ],
                ))));
  }
}
