import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'client.dart';

class FrontPage extends StatefulWidget {
  final String title;

  FrontPage({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  int _selectedIndex = 0; //New

// //New
  static const List<Widget> _pages = <Widget>[
    Contacts(),
    //Album()
    //Files()
    Icon(
      Icons.call,
      size: 150,
    ),
    // Show album list
    Icon(
      Icons.camera,
      size: 150,
    ),
    Icon(
      Icons.chat,
      size: 150,
    ),
  ];

  // static List<MaterialPageRoute> materialPage = <MaterialPageRoute>[
  //   MaterialPageRoute(builder: (context) => SelectPage(title: "Select Page",)),
  //   MaterialPageRoute(builder: (context) => SelectPage(title: "Select Page",)),
  //   MaterialPageRoute(builder: (context) => SelectPage(title: "Select Page",)),
  // ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print(_selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
          body: IndexedStack(
            children: _pages,
            index: _selectedIndex,
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
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          )),
    );
  }
}

class Contacts extends StatefulWidget {
  const Contacts();

  @override
  _Contacts createState() => _Contacts();
}

class _Contacts extends State<Contacts> {
  Widget build(BuildContext context) {
    Logger.level = Level.debug;

    int itemCount = 15;

    var contacts = new Map();
    contacts = {
      "robin": 1,
      "Duncan": 2,
      "we": 1,
      "asd": 2,
      "asf": 1,
      "saf": 2,
      "sd": 1,
      "zxv": 2,
      "wet": 1,
      "xzc": 2,
      "vzx": 1,
      " zx": 2,
      "fas": 1,
      "Duncavnn": 2,
    };

    String add = '';
    bool shouldDisplay = false;

    final Size size = MediaQuery.of(context).size;
    double padding = 10;
    final sidePadding =
        EdgeInsets.symmetric(horizontal: padding, vertical: padding);
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                // color: Colors.black54,
                ),
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Padding(padding: sidePadding),
                    Text("Your ID: $add"),
                    TextButton(
                        onPressed: addCode,
                        child: Text("Click me to get addCode"))
                  ],
                ),
                Container(
                  height: 300,
                  width: 400,
                  child: itemCount > 0
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: itemCount,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                                //TODO need to implement delete file from file list
                                title: Text(contacts.keys.toList()[index]));
                          },
                        )
                      : Center(),
                ),
              ],
            )));

    // Container(
    //     width: size.width,
    //     height: size.height,
    // child: Stack(
    //   children: [
    //     Padding(
    //       padding: sidePadding,
    //       child: Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           BoarderBox(
    //               padding: sidePadding,
    //               width: 100,
    //               height: 50,
    //               child: Text('Contacts'))
    //         ],
    //       ),
    //     )
    //   ],
    // )
    // )
  }
}
// extendBody: Container,
//  Container(

//     child: Column(children: [
//       Padding(
//           padding: EdgeInsets.symmetric(
//               vertical: padding, horizontal: padding),
//           child:
//           Row(mainAxisAlignment: MainAxisAlignment.end, children: [
//             BoarderBox(
//               width: 50,
//               height: 50,
//               padding: const EdgeInsets.all(8.0),
//               child: Icon(
//                 Icons.person_add,
//                 color: Colors.black,
//               ),
//             )
//           ])
//       )
//     ])),
