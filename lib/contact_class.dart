import 'package:flutter/material.dart';

class Person {
  String fullName;

  // String lastName;
  String pubKey;

  Person(this.fullName, this.pubKey);
}

class PersonTile extends StatelessWidget {
  PersonTile(this._person);

  final Person _person;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text(_person.fullName),
      subtitle: Text(_person.pubKey.substring(0, 5)),
      // trailing: PersonHandIcon(_person.isLeftHand),
    );
  }
}

class HeaderTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Text(
      "Friends",
      style: TextStyle(fontSize: 20),
    ));
  }
}

var totalContact = [];
