import 'package:flutter/material.dart';

class User {
  String fullName;

  // String lastName;
  String pubKey;

  User({required String fullName, required String pubKey})
      : this.fullName = fullName,
        this.pubKey = pubKey;

  static User fromMap(Map map) {
    return User(fullName: map['fullName'], pubKey: map['pubKey']!);
  }

  Map toMap() {
    return {'fullName': this.fullName, 'pubKey': this.pubKey};
  }
}


class UsersTile extends StatelessWidget {
  UsersTile(this._contact);

  final User _contact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person),
      title: Text(_contact.fullName),
      subtitle: Text(_contact.pubKey.toString().substring(0, 5)),
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

// void addToContact()
