import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';


class FrontPage extends StatefulWidget {
  FrontPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/rocket.webp"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Spacer(),
                  Text(
                    'connect_ME',
                    style: GoogleFonts.lobster(
                     textStyle: TextStyle(fontSize: 45, color: Colors.pink),
                  ),
                  ),
                  Spacer(),
                  Spacer(),
                  Spacer(),
                  OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                        );
                      },
                      child: Text(
                        "🚀  Send Files",
                        style: TextStyle(fontSize: 20, color: Colors.pink),
                      )),
                  // OutlinedButton(
                  //     onPressed: null,
                  //     child: Text(
                  //       "📋  Send Clipboard",
                  //       style: TextStyle(fontSize: 20),
                  //     )),
                  Spacer(),
                ],
              ),
            )));
  }
}

