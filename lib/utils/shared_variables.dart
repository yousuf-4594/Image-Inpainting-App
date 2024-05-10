import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SharedVariables extends ChangeNotifier {
  String _url = ""; // Default locale

  String get url => _url;

  void setURL(String value) {
    _url = value;
    print("Value set $value");
    notifyListeners();
  }
}
