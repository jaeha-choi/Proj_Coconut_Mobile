import 'package:flutter/material.dart';

import 'screens/front_page.dart';

Future<void> main() async {
  // Client client = await newClient();
  // print(client.serverIP)
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
      debugShowCheckedModeBanner: true,
      home: FrontPage(),
    );
    // );
  }
// Future _getThingsOnStartup() async {
//   this.client = await newClient();
//   if (client == null) {
//     //     TODO: Error handling
//     print("Client is null");
//   }
//   await this.client.connect(this.client);
//   await this.client.doGetAddCode(this.client);
//   return this.client;
// }
}

/// Wrapper for stateful functionality to provide onInit calls in stateles widget
class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;

  const StatefulWrapper({required this.onInit, required this.child});

  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<StatefulWrapper> {
  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
