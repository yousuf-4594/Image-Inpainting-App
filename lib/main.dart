import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  Image? _uploadedImage;

  Future<void> _getImage() async {
    print("[INFO] Get Image button pressed");
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      return;
    }

    final apiUrl = 'https://wicked-walls-unite.loca.lt/api/inpaint/';
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['text'] = 'Your text data here'; // Add your text data here
      request.files.add(
        http.MultipartFile(
          'image',
          File(_image!.path).readAsBytes().asStream(),
          File(_image!.path).lengthSync(),
          filename: basename(_image!.path),
        ),
      );

      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        // Handle success
        setState(() {
          _uploadedImage = Image.memory(response.bodyBytes);
        });
        print('Image uploaded successfully');
      } else {
        // Handle error
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or exceptions
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) ...[
              Image.file(_image!),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
            if(_uploadedImage != null)...[
              SizedBox(height: 20,),
              _uploadedImage!,
            ]
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}
