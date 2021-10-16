import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../client.dart';
import 'album_page.dart';
import 'contacts_page.dart';
import 'file_page.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({Key? key}) : super(key: key);

  // FrontPage({required Client? client}) : this.client = client;

  @override
  State<StatefulWidget> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  late Client client;
  bool init = false;
  Future? myFuture;

  @override
  void initState() {
    myFuture = initClient();
  }

  Future initClient() async {
    if (!this.init) {
      print("Should only print one time");
      this.client = await createClient();
      this.init = true;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _index = index;
      print(_index);
    });
  }

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: myFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Scaffold(
                  bottomNavigationBar: BottomNavigationBar(
                    iconSize: 30,
                    selectedFontSize: 15,
                    selectedIconTheme:
                        IconThemeData(color: Colors.teal, size: 30),
                    selectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
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
                  ),
                  body: IndexedStack(
                    index: _index,
                    children: <Widget>[
                      Contacts(client: client),
                      Album(client: client),
                      SelectFile(client: client),
                    ],
                  ));
            } else {
              // if (snapshot.connectionState == ConnectionState.waiting) {
              return new CircularProgressIndicator();
              // }else
            }
          }),
    );
  }
}
