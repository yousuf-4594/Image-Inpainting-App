import 'package:flutter/material.dart';
import 'package:image_inpainting/utils/shared_variables.dart';
import 'package:provider/provider.dart';

class settings_screen extends StatefulWidget {
  @override
  _settings_screen createState() => _settings_screen();
}

class _settings_screen extends State<settings_screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Settings'),
            Icon(Icons.qr_code_2_rounded),
          ],
        ),
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 110,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 100,
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/avatar_logo.jpeg'),
                  ),
                  Positioned(
                    top: 160,
                    child: Text(
                      'Yousuf Ahmed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: Text(
                  'Design is not just what it looks like and feels like. Design is how it works.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 90),
              Divider(color: Colors.black12, height: 1),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "IP address 1...",
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      Provider.of<SharedVariables>(context, listen: false).setURL(text);
                    },
                  ),
                ),
              ),
              Divider(color: Colors.black12, height: 1),
              Divider(color: Colors.black12, height: 1),
              // GestureDetector(
              //   onTap: () {
              //     print("save information");
              //   },
              //   child: Container(
              //     height: 50,
              //     child: Center(
              //         child: Text(
              //       "Save information",
              //     )),
              //     decoration: BoxDecoration(color: Colors.black12),
              //   ),
              // ),
              Divider(color: Colors.black12, height: 1),
            ],
          ),
        ],
      ),
    );
  }
}
