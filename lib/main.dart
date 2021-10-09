import 'package:flutter/material.dart';

// import 'package:mobile_app/front_page.dart';
import 'front_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      home: FrontPage(title: 'Team Coconut'),
    );
  }
}
