import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final fullName = TextEditingController();
  final addCode = TextEditingController();

  Client client;

  _Contacts(this.client);

  List<User> friendsList = <User>[];
  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    initSharedPreferences();
    super.initState();
    // final prefs = await SharedPreferences.getInstance();
  }

  Widget buildListView() {
    return ListView.builder(
      itemCount: friendsList.length,
      itemBuilder: (BuildContext context, int index) {
        return buildItem(friendsList[index], index);
      },
    );
  }

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool isDone = state == ButtonState.done;
    bool isOnLine = state == ButtonState.init;


    void changeStatus() {
      isOnLine = !isOnLine;
      setState(() {});
    }

    void changeText() {
      setState(() {
        client.addCode = client.addCode;
      });
    }

    Widget buildOffLine(bool isOnLine) => ElevatedButton(
        onPressed: () async {
          setState(() => state = ButtonState.loading);
          await Future.delayed(Duration(seconds: 2));

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
          if (client.addCode.length != 0) {
            await client.doRemoveAddCode();
            setState(() => state = ButtonState.loading);
            await Future.delayed(Duration(seconds: 2));
            changeStatus();
            changeText();
            setState(() => state = ButtonState.done);
          } else {
            setState(() => state = ButtonState.loading);
            await Future.delayed(Duration(seconds: 2));
            changeStatus();
            changeText();
            setState(() => state = ButtonState.done);
          }
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
                                      controller: fullName,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Enter a full name'),
                                    ),
                                    Padding(padding: sidePadding),
                                    TextField(
                                      controller: addCode,
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
                                  onPressed: () async {
                                    List requestPubKey =
                                        await client.doRequestPubKey(
                                            addCode.text, fullName.text);
                                    // .code == 0 means the server found recipient's add code
                                    if (requestPubKey.first.code == 0) {
                                      addUser(User(
                                          fullName: fullName.text,
                                          pubKey: requestPubKey.last));
                                      Navigator.pop(context, 'OK');
                                      setState(() {});
                                    } else {
                                      Navigator.pop(context, 'OK');
                                    }
                                    // addToContact();
                                  },
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
                    Expanded(child: buildListView()),
                    // height: 600,
                    // width: 400,
                    //     child: ListView.builder(
                    //   padding: const EdgeInsets.all(8),
                    //   itemCount: friendsList.length,
                    //   itemBuilder: (BuildContext context, int index) {
                    //     // print(itemCount);
                    //
                    //     // if (itemCount == 0) return HeaderTile();
                    //     return UsersTile(friendsList[index]);
                    //   },
                    //   //       shrinkWrap: true,
                    //   //       itemCount: itemCount,
                    //   //       itemBuilder: (BuildContext context, int index) {
                    //   //      return ListTile(
                    //   //         //TODO need to implement delete file from file list
                    //   //
                    //   //           title: Text(contacts.keys.toList()[index]));
                    //   // },
                    // )),
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
                                    if (isOnLine &&
                                        client.addCode.length != 0) {
                                      logger.i('remove');
                                      await client.doRemoveAddCode();
                                      await client.doGetAddCode();
                                      changeText();
                                    }
                                    if (isOnLine &&
                                        client.addCode.length == 0) {
                                      logger.i('add');
                                      await client.doGetAddCode();
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
                                        client.addCode.length == 6) {
                                      await client.doRemoveAddCode();
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
                                  // utf8.decode(client.listOfChannel['AR']?.takeBytes()),
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

  Widget buildItem(User item, index) {
    return Dismissible(
      key: Key('${item.hashCode}'),
      background: Container(color: Colors.red[700]),
      onDismissed: (DismissDirection endToStart) => removeItem(item),
      direction: DismissDirection.endToStart,
      child: buildListTile(item, index),
    );
  }

  Widget buildListTile(User item, int index) {
    // print(item.completed);
    return ListTile(
      // onTap: () => changeItemCompleteness(item),
      onLongPress: () => send(),
      title: Text(
        item.fullName,
        key: Key('item-$index'),
        style: TextStyle(),
      ),
      subtitle: Text(item.pubKey.toString().substring(0, 5)),
    );
    // trailing: Icon(item.completed
    //     ? Icons.check_box
    //     : Icons.check_box_outline_blank,
    //   key: Key('completed-icon-$index'),
    // ),
    // );
  }

  void send() {
    // AesGcmChunk encrypt = encryptSetup();
  }

  void removeItem(User item) {
    friendsList.remove(item);
    saveData();
  }

  initSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    _loadData();
  }

  void addUser(User item) {
    friendsList.add(item);
    saveData();
  }

  void saveData() {
    List<String> spList =
        friendsList.map((item) => json.encode(item.toMap())).toList();
    sharedPreferences.setStringList("list", spList);
    print(spList);
  }

  void _loadData() {
    List<String> spList = sharedPreferences.getStringList('list')!;
    friendsList =
        spList.map((item) => User.fromMap(json.decode(item))).toList();
    setState(() {});
  }
}
