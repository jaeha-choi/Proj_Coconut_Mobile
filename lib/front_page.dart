import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Album.dart';
import 'File.dart';
import 'client.dart';
import 'contacts.dart';


class FrontPage extends StatefulWidget {
  Client? client;

  FrontPage({required Client? client}) : this.client = client;

  @override
  State<StatefulWidget> createState() => _FrontPageState(client);
}

class _FrontPageState extends State<FrontPage> {
  Client? client;

  _FrontPageState(this.client);

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

    // switch (_index) {
    //   // Contacts
    //   case 0:
    //     widget = Contacts(client: client);
    //     break;
    //   // Album
    //   case 1:
    //     widget = Album(client: client);
    //     break;
    //   case 2:
    //   // widget = ();
    // }

    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              widget = Contacts(client: client),
              widget = Album(client: client),
              widget = SelectFile(client: client),
            ],
          ),

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
            currentIndex: _index,
            onTap: _onItemTapped,
          )),
    );
  }
}
