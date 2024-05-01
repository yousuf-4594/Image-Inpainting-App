import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ai_screen extends StatefulWidget {
  @override
  _ai_screen createState() => _ai_screen();
}

class _ai_screen extends State<ai_screen> {
  File? _image;
  File? _maskImage;
  Image? _uploadedImage;

  String _baseUrl = "";
  String text = "";

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

  Future<void> _getMaskImage() async {
    final maskImagePicker = ImagePicker();
    final maskPickedFile =
        await maskImagePicker.pickImage(source: ImageSource.gallery);
    if (maskPickedFile != null) {
      setState(() {
        _maskImage = File(maskPickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Picture'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1.0, // Adjust border width as needed
                ),
                borderRadius: BorderRadius.circular(
                    5.0), // Adjust border radius as needed
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _baseUrl = value;
                  });
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1.0, // Adjust border width as needed
                ),
                borderRadius: BorderRadius.circular(
                    5.0), // Adjust border radius as needed
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    text = value;
                  });
                },
              ),
            ),
            if (_image != null) ...[
              Container(width: 150, height: 150, child: Image.file(_image!)),
              SizedBox(height: 20),
            ],
            if (_maskImage != null) ...[
              Container(
                  width: 150, height: 150, child: Image.file(_maskImage!)),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Select Input Image'),
            ),
            ElevatedButton(
              onPressed: _getMaskImage,
              child: Text('Select Mask Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
            if (_uploadedImage != null) ...[
              SizedBox(
                height: 20,
              ),
              Container(width: 250, height: 250, child: _uploadedImage!),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      return;
    }

    final apiUrl = '$_baseUrl/api/inpaint/';
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers["bypass-tunnel-reminder"] = "true";
      request.fields['text'] = text; // Add your text data here
      request.files.add(
        http.MultipartFile(
          'image',
          File(_image!.path).readAsBytes().asStream(),
          File(_image!.path).lengthSync(),
          filename: basename(_image!.path),
        ),
      );
      request.files.add(
        http.MultipartFile(
          'mask',
          File(_maskImage!.path).readAsBytes().asStream(),
          File(_maskImage!.path).lengthSync(),
          filename: basename(_maskImage!.path),
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
}
