import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../client.dart';
import 'album_page.dart';
import 'contacts_page.dart';
import 'file_page.dart';

class FrontPage extends StatefulWidget {
  // Client? client;
  const FrontPage({Key? key}) : super(key: key);

  // FrontPage({required Client? client}) : this.client = client;

  @override
  State<StatefulWidget> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  late Client client;

  // _FrontPageState(this.client);

  @override
  void initState() {
    createClient().then((result) {
      setState(() {
        client = result;
      });
    });
  }

  _getThingsOnStartup() async {
    return await createClient();
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
    // Widget widget = Container();

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

    if (client == null) {
      // This is what we show while we're loading
      return new Container();
    }

    return SafeArea(
      child: Scaffold(
          body: IndexedStack(
            index: _index,
            children: <Widget>[
              Contacts(client: client),
              Album(client: client),
              SelectFile(client: client),
            ],
          ),
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
