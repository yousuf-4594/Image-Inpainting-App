import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_inpainting/utils/shared_variables.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import "package:http/http.dart" as http;

class ai_screen extends StatefulWidget {
  @override
  _ai_screenState createState() => _ai_screenState();
}

class _ai_screenState extends State<ai_screen> {
  File? _pickedImage;
  File? _maskImage;
  Image? _uploadedImage;
  late String _text;
  List<Offset> _points = <Offset>[];
  Color _drawColor = Colors.white;
  late String dir;

  late GlobalKey _paintKey;
  late GlobalKey _repaintBoundaryKey;
  late GlobalKey _imgkey;
  late int img_height;
  late int img_width;
  late String _maskImagePath;

  void loadDir() async{
    String path = (await getExternalStorageDirectory())!.path;
    setState(() {
      dir = path;
      _maskImagePath = '$path/mask.png';
    });
    print("Directory Loaded: $dir");
    print("Mask Image Directory Loaded: $_maskImagePath");
  }

  @override
  void initState() {
    loadDir();
    super.initState();
    _paintKey = GlobalKey();
    _repaintBoundaryKey = GlobalKey();
    _imgkey = GlobalKey();

  }

  Future<File> loadImageFromFile(String imagePath) async {
    File imageFile = File(imagePath);
    if (await imageFile.exists()) {
      return imageFile;
    } else {
      throw Exception('Image file does not exist');
    }
  }

  Future<void> printImageDimensions(String imagePath) async {
    // Read the image file
    File imageFile = File(imagePath);
    Uint8List bytes = await imageFile.readAsBytes();

    // Decode the image
    ui.Image image = await decodeImageFromList(bytes);

    // Print the dimensions
    print('Image dimensions: ${image.width} x ${image.height}');
  }

  Future<void> _openImagePicker() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });
    } else {
      if (kDebugMode) {
        print('No image selected.');
      }
    }
  }

  Map<String, Offset> getContainerCoordinates(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final bottomRight =
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero));

    final startingCoordinates = Offset(topLeft.dx, topLeft.dy);
    final endingCoordinates = Offset(bottomRight.dx, bottomRight.dy);


    return {
      'startingCoordinates': startingCoordinates,
      'endingCoordinates': endingCoordinates,
    };
  }

  Future<void> _getMaskImage() async{
    try{
      File imageFile = await loadImageFromFile(_maskImagePath);
      setState(() {
        _maskImage = null;
        _maskImage = imageFile;
      });
      print("Mask Image loaded: $_maskImagePath");
    }catch(e){
      print("Error loading image: $e");
    }
  }

  Future<void> _uploadImage(context) async {
    await _getMaskImage();
    print("Mask Image Path: $_maskImage, File Path: $_pickedImage");
    if (_pickedImage == null || _maskImage == null) {
      return;
    }

    await printImageDimensions(_maskImagePath);

    String _baseUrl = SharedVariables.getURL();

    final apiUrl = '$_baseUrl/api/inpaint/';
    print(apiUrl);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers["bypass-tunnel-reminder"] = "true";
      request.fields['text'] = _text; // Add your text data here
      request.files.add(
        http.MultipartFile(
          'image',
          File(_pickedImage!.path).readAsBytes().asStream(),
          File(_pickedImage!.path).lengthSync(),
          filename: basename(_pickedImage!.path),
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
                              key: _imgkey,
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
                                print('${localPosition}');
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
                              onChanged: (text) {
                                _text = text;
                              },
                            ),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              _save(context);
                              Future.delayed(Duration(seconds: 3), (){
                                _uploadImage(context);
                              });

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
      final orignalWidth = imageSize.width;
      final orignalHeight = imageSize.height;

      final maxWidth = MediaQuery.of(context).size.width;
      final maxHeight = MediaQuery.of(context).size.height;

      var x = min(orignalWidth / maxWidth, orignalHeight / maxHeight);
      print('image has been scaled down by $x in this app due to boxfit');

      // final imgWidth = orignalWidth / x;
      // final imgHeight = orignalHeight / x;

      final imgWidth = maxWidth;
      final imgHeight = maxHeight;

      Map<String, Offset> coordinates = getContainerCoordinates(_imgkey);
      double containerTopLeftX = coordinates['startingCoordinates']!.dx;
      double containerTopLeftY = coordinates['startingCoordinates']!.dy;
      double containerBottomRightX = coordinates['endingCoordinates']!.dx;
      double containerBottomRightY = coordinates['endingCoordinates']!.dy;

      // Create a new image with the drawn points
      final recorder = ui.PictureRecorder();
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

      final img = await picture.toImage(imgWidth.toInt(), imgHeight.toInt());

      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngList = pngBytes!.buffer.asUint8List();

      final String filePath = _maskImagePath;

      File(filePath).writeAsBytesSync(pngList);

      // Clear the drawn points
      setState(() {
        _points.clear();
      });
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
        },
      ),
    );
    return completer.future;
  }

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
