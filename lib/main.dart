import 'package:flutter/material.dart';

import 'screens/front_page.dart';

Future<void> main() async {
  /// User preference should run in main method?? TODO
  // WidgetsFlutterBinding.ensureInitialized();
  // await SharedPreferences.getInstance();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      home: FrontPage(),
    );
  }
}
