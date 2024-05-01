import 'package:flutter/material.dart';

class home_screen extends StatefulWidget {
  @override
  _home_screen createState() => _home_screen();
}

class _home_screen extends State<home_screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
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
