import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'client.dart';
import 'contacts.dart';


class FrontPage extends StatefulWidget {
  final String title;

  FrontPage({Key? key, required this.title}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {

  // TODO need initialize client, when user starting the app
  Client? client;

  @override
  void initState() {
    // This is the proper place to make the async calls
    // This way they only get called once

    // During development, if you change this code,
    // you will need to do a full restart instead of just a hot reload

    // You can't use async/await here, because
    // We can't mark this method as async because of the @override
    // You could also make and call an async method that does the following
    loadAsyncData().then((val) {
      // If we need to rebuild the widget with the resulting data,
      // make sure to use `setState`
      setState(() {
        client = val!;
      });
    });
  }

  Future<Client?> loadAsyncData() async {
    Client? client = await newClient();
    if (client == null) {
      // TODO: Error handling
      print("Client is null");
    }
    await client!.connect(client);
    await client.doGetAddCode(client);
    return client;
  }

  int _selectedIndex = 0; //New

  // ///New
  // static  List<Widget> _pages = <Widget>[
  //    Contacts(client : client),
  //   //Album()
  //   //Files()
  //   Icon(
  //     Icons.call,
  //     size: 150,
  //   ),
  //   // Show album list
  //   Icon(
  //     Icons.camera,
  //     size: 150,
  //   ),
  //   Icon(
  //     Icons.chat,
  //     size: 150,
  //   ),
  // ];


  void _onItemTapped(int index) {
    setState(() {
      _index = index;
      print(_index);
    });
  }

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    Widget widget = Container();

    switch (_index) {
    // Contacts
      case 0:
        widget = Contacts(client: client);
        break;

      case 1:
        widget = FlutterLogo();
        break;
    }

    final Size size = MediaQuery
        .of(context)
        .size;
    return SafeArea(
      child: Scaffold(
        // body: IndexedStack(
        //   children: _pages,
        //   index: _selectedIndex,
        // ),
          body: widget,

          //
          bottomNavigationBar: BottomNavigationBar(
            iconSize: 30,
            selectedFontSize: 15,
            selectedIconTheme: IconThemeData(color: Colors.teal, size: 30),
            selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            backgroundColor: Colors.black54,
            elevation: 0,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.photo_album),
                label: 'Album',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder),
                label: 'File',
              )
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          )),
    );
  }
}
