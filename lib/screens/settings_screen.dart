import 'package:flutter/material.dart';

class settings_screen extends StatefulWidget {
  @override
  _settings_screen createState() => _settings_screen();
}

class _settings_screen extends State<settings_screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text(
          'Hello',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
