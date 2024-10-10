import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String useLater;

  UserProvider({
    this.useLater = "TODO",
  });

  void updateStr({
    required String newStr,
  }) async {
    useLater = newStr;
    notifyListeners();
  }
}