import 'package:flutter/material.dart';

import 'client.dart';
import 'front_page.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Client? client;

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

  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
        onInit: () {
          _getThingsOnStartup().then((value) {
            print('Async done');
            client = value;
            print(client!.addCode);
          });
        },
        child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.teal,
            brightness: Brightness.dark,
          ),
          debugShowCheckedModeBanner: false,
          home: FrontPage(client: client),
        ));
  }

  Future<Client?> _getThingsOnStartup() async {
    client = await loadAsyncData();
    return client;
  }
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
