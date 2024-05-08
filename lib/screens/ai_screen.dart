import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

class ai_screen extends StatefulWidget {
  @override
  _ai_screenState createState() => _ai_screenState();
}

class _ai_screenState extends State<ai_screen> {
  File? _pickedImage;
  List<Offset> _points = <Offset>[];
  Color _drawColor = Colors.red;

  late GlobalKey _paintKey;
  late GlobalKey _repaintBoundaryKey;
  late int img_height;
  late int img_width;

  @override
  void initState() {
    super.initState();
    _paintKey = GlobalKey();
    _repaintBoundaryKey = GlobalKey();
  }

  Future<void> _openImagePicker() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: _pickedImage == null
                  ? Center(
                      child: GestureDetector(
                        onTap: _openImagePicker,
                        child: Icon(
                          Icons.image_search_outlined,
                          color: Colors.black54,
                          size: 50,
                        ),
                      ),
                    )
                  : RepaintBoundary(
                      key: _repaintBoundaryKey,
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              child: Image.file(
                                _pickedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                Offset localPosition = renderBox
                                    .globalToLocal(details.globalPosition);
                                // print('${localPosition}');
                                draw(localPosition);
                              });
                            },
                          ),
                          CustomPaint(
                            key: _paintKey,
                            isComplex: true,
                            painter: _DrawingPainter(
                              points: _points,
                              color: _drawColor,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Divider(
              height: 1,
              color: Colors.black54,
            ),
            Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Enter Prompt Here...",
                                border: InputBorder.none,
                              ),
                              onChanged: (text) {},
                            ),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              _save(context);
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.15,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ))
                      ],
                    ),
                    Divider(
                      height: 1,
                      color: Colors.black54,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.draw, color: Colors.black),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.undo, color: Colors.black),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.download_rounded, color: Colors.black),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.collections, color: Colors.black),
                          onPressed: _openImagePicker,
                        ),
                      ],
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) async {
    // Check if there are any points to draw and if an image is loaded
    if (_points.isNotEmpty && _pickedImage != null) {
      // Get the size of the loaded image
      final imageSize = await _getImageSize(_pickedImage!.path);
      final imgWidth = imageSize.width;
      final imgHeight = imageSize.height;

      // Create a new image with the drawn points
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = _drawColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 70.0;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          // Check if the point is within the image bounds
          if (_isPointWithinBounds(_points[i]!, imgWidth, imgHeight) &&
              _isPointWithinBounds(_points[i + 1]!, imgWidth, imgHeight)) {
            canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
          }
        }
      }

      // Convert the image to a PNG byte array
      final picture = recorder.endRecording();
      final img = await picture.toImage(
          MediaQuery.of(context).size.width.toInt(),
          MediaQuery.of(context).size.height.toInt());
      final pngBytes = await img.toByteData(format: ImageByteFormat.png);
      final Uint8List pngList = pngBytes!.buffer.asUint8List();

      // Save the image to the device's download directory
      final String dir = (await getExternalStorageDirectory())!.path;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '$dir/drawn_image_$timestamp.png';
      File(filePath).writeAsBytesSync(pngList);

      // Clear the drawn points
      setState(() {
        _points.clear();
      });
      print('Image saved to $dir/drawn_image_$timestamp.png');
    }
  }

// Function to get the size of the loaded image
  Future<Size> _getImageSize(String imagePath) async {
    final completer = Completer<Size>();
    final image = Image.file(File(imagePath));
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          final imageWidth = info.image.width.toDouble();
          final imageHeight = info.image.height.toDouble();
          completer.complete(Size(imageWidth, imageHeight));
          print('$imageWidth $imageHeight');
        },
      ),
    );
    return completer.future;
  }

// Function to check if a point is within the image bounds
  bool _isPointWithinBounds(Offset point, double imgWidth, double imgHeight) {
    return point.dx >= 0 &&
        point.dx <= imgWidth &&
        point.dy >= 0 &&
        point.dy <= imgHeight;
  }

  void draw(Offset point) {
    setState(() {
      _points = List.from(_points)..add(point);
    });
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  _DrawingPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 70.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// File? _image;
//   File? _maskImage;
//   Image? _uploadedImage;

//   String _baseUrl = "";
//   String text = "";

//   Future<void> _getImage() async {
//     print("[INFO] Get Image button pressed");
//     final imagePicker = ImagePicker();
//     final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _getMaskImage() async {
//     final maskImagePicker = ImagePicker();
//     final maskPickedFile =
//         await maskImagePicker.pickImage(source: ImageSource.gallery);
//     if (maskPickedFile != null) {
//       setState(() {
//         _maskImage = File(maskPickedFile.path);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Take Picture'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Colors.black,
//                   width: 1.0, // Adjust border width as needed
//                 ),
//                 borderRadius: BorderRadius.circular(
//                     5.0), // Adjust border radius as needed
//               ),
//               child: TextField(
//                 onChanged: (value) {
//                   setState(() {
//                     _baseUrl = value;
//                   });
//                 },
//               ),
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Colors.black,
//                   width: 1.0, // Adjust border width as needed
//                 ),
//                 borderRadius: BorderRadius.circular(
//                     5.0), // Adjust border radius as needed
//               ),
//               child: TextField(
//                 onChanged: (value) {
//                   setState(() {
//                     text = value;
//                   });
//                 },
//               ),
//             ),
//             if (_image != null) ...[
//               Container(width: 150, height: 150, child: Image.file(_image!)),
//               SizedBox(height: 20),
//             ],
//             if (_maskImage != null) ...[
//               Container(
//                   width: 150, height: 150, child: Image.file(_maskImage!)),
//               SizedBox(height: 20),
//             ],
//             ElevatedButton(
//               onPressed: _getImage,
//               child: Text('Select Input Image'),
//             ),
//             ElevatedButton(
//               onPressed: _getMaskImage,
//               child: Text('Select Mask Image'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _uploadImage,
//               child: Text('Upload Image'),
//             ),
//             if (_uploadedImage != null) ...[
//               SizedBox(
//                 height: 20,
//               ),
//               Container(width: 250, height: 250, child: _uploadedImage!),
//             ]
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _uploadImage() async {
//     if (_image == null) {
//       return;
//     }

//     final apiUrl = '$_baseUrl/api/inpaint/';
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
//       request.headers["bypass-tunnel-reminder"] = "true";
//       request.fields['text'] = text; // Add your text data here
//       request.files.add(
//         http.MultipartFile(
//           'image',
//           File(_image!.path).readAsBytes().asStream(),
//           File(_image!.path).lengthSync(),
//           filename: basename(_image!.path),
//         ),
//       );
//       request.files.add(
//         http.MultipartFile(
//           'mask',
//           File(_maskImage!.path).readAsBytes().asStream(),
//           File(_maskImage!.path).lengthSync(),
//           filename: basename(_maskImage!.path),
//         ),
//       );

//       var response = await http.Response.fromStream(await request.send());

//       if (response.statusCode == 200) {
//         // Handle success
//         setState(() {
//           _uploadedImage = Image.memory(response.bodyBytes);
//         });
//         print('Image uploaded successfully');
//       } else {
//         // Handle error
//         print('Failed to upload image: ${response.statusCode}');
//       }
//     } catch (e) {
//       // Handle network errors or exceptions
//       print('Exception: $e');
//     }
//   }
