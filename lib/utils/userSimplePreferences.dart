import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserSimplePreferences {
  static SharedPreferences? _preferences;
  late String name;
  late String pubKey;

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  UserSimplePreferences.fromMap(Map map) {
    this.name = map['name'];
    this.pubKey = map['pubkey'];
  }

  Map toMap() {
    return {
      'user': this.name,
      'pubKey': this.pubKey,
    };
  }

  /// Saves [String]recipient name and [String]recipient's public key locally
  Future saveUser(String recipientName, String pubKeyString) async {
    await _preferences?.setString(recipientName, pubKeyString);
  }

  void saveData(List<UserSimplePreferences> list) {
    List<String> spList =
        list.map((item) => json.encode(item.toMap())).toList();
    // print(spList);
  }
}
