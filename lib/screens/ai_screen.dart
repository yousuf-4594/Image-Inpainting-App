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
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
  Color _drawColor = Colors.blueAccent;
  late String dir;

  late GlobalKey _paintKey;
  late GlobalKey _repaintBoundaryKey;
  late GlobalKey _imgkey;
  late int img_height;
  late int img_width;
  late String _maskImagePath;
  TextEditingController _controller = TextEditingController();
  bool _loadingInput = false;

  double _sliderValue = 0.0;
  bool _sliderVisible = false;

  void loadDir() async {
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

  Future<Map<String, String>> getImageDimensions(String imagePath) async {
    // Read the image file
    File imageFile = File(imagePath);
    Uint8List bytes = await imageFile.readAsBytes();

    // Decode the image
    ui.Image image = await decodeImageFromList(bytes);

    // Print the dimensions
    return {"width": "${image.width}", "height": "${image.height}"};
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

  Future<void> _getMaskImage() async {
    try {
      File imageFile = await loadImageFromFile(_maskImagePath);
      setState(() {
        _maskImage = null;
        _maskImage = imageFile;
      });
      print("Mask Image loaded: $_maskImagePath");
    } catch (e) {
      print("Error loading image: $e");
    }
  }

  Future<void> _uploadImage(context) async {
    await _getMaskImage();
    print("Mask Image Path: $_maskImage, File Path: $_pickedImage");
    if (_pickedImage == null || _maskImage == null) {
      return;
    }

    Map<String, String> dimensions =
        await getImageDimensions(_pickedImage!.path);

    String _baseUrl = SharedVariables.getURL();

    final apiUrl = '$_baseUrl/api/inpaint/';
    print(apiUrl);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers["bypass-tunnel-reminder"] = "true";
      request.fields['text'] = _text; // Add your text data here
      request.fields["width"] = dimensions["width"]!;
      request.fields["height"] = dimensions["height"]!;

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
      showSnackbar(context, 'Image uploaded to server', 1);
      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        // Handle success
        // setState(() {
        //   _uploadedImage = Image.memory(response.bodyBytes);
        // });

        // Convert the received image bytes to a File object and assign it to _pickedImage
        final String dir = (await getExternalStorageDirectory())!.path;
        final String timestamp =
            DateTime.now().millisecondsSinceEpoch.toString();
        final String filePath = '$dir/uploaded_image_$timestamp.png';
        await File(filePath).writeAsBytes(response.bodyBytes);
        print(filePath);

        setState(() {
          _pickedImage = File(filePath);
          _loadingInput = false;
        });

        print('Image uploaded successfully');
      } else {
        setState(() {
          _loadingInput = false;
        });

        // Handle error
        print('Failed to upload image: ${response.statusCode}');
        showSnackbar(
            context, 'Failed to upload image: ${response.statusCode}', 1);
      }
    } catch (e) {
      setState(() {
        _loadingInput = false;
      });
      // Handle network errors or exceptions
      showSnackbar(context, 'Exception $e', 1);
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
                                _sliderVisible = false;
                              });
                              Map<String, Offset> coordinates =
                                  getContainerCoordinates(_imgkey);
                              double containerTopLeftX =
                                  coordinates['startingCoordinates']!.dx;
                              double containerTopLeftY =
                                  coordinates['startingCoordinates']!.dy;
                              double containerBottomRightX =
                                  coordinates['endingCoordinates']!.dx;
                              double containerBottomRightY =
                                  coordinates['endingCoordinates']!.dy;

                              RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                              Offset localPosition = renderBox
                                  .globalToLocal(details.globalPosition);

                              print(coordinates);

                              if (localPosition.dx - 34 >= containerTopLeftX &&
                                  localPosition.dx + 34 <=
                                      containerBottomRightX &&
                                  localPosition.dy - 34 >= containerTopLeftY &&
                                  localPosition.dy + 34 <=
                                      containerBottomRightY) {
                                setState(() {
                                  print('${localPosition}');
                                  draw(localPosition);
                                });
                              }
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
                          if (_sliderVisible == true)
                            Positioned(
                              top: MediaQuery.of(context).size.height * 0.72,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                child: Slider(
                                  value: _sliderValue,
                                  min: 0.0,
                                  max: 100.0,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _sliderValue = newValue;
                                    });
                                  },
                                  activeColor: Colors.blueAccent.shade700,
                                  inactiveColor: Colors.blue.shade100,
                                ),
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
                          padding: const EdgeInsets.only(left: 15.0),
                          child: SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Input Prompt...",
                                border: InputBorder.none,
                              ),
                              cursorColor: Colors.transparent,
                              onChanged: (text) {
                                _text = text;
                              },
                            ),
                          ),
                        ),
                        if (_loadingInput == false)
                          GestureDetector(
                              onTap: () {
                                if (_controller.text.isEmpty) {
                                  showSnackbar(
                                      context, 'Input prompt empty', 1);
                                } else if (_points.isEmpty) {
                                  showSnackbar(
                                      context, 'No Input Mask generated', 1);
                                } else {
                                  setState(() {
                                    _sliderVisible = false;
                                    _controller.clear();
                                    _loadingInput = true;
                                  });
                                  _save(context);
                                  Future.delayed(Duration(seconds: 3), () {
                                    _uploadImage(context);
                                  });
                                }
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
                        else if (_loadingInput == true)
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.15,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          )
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
                          icon: Icon(Icons.draw, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _sliderVisible = !_sliderVisible;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.undo, color: Colors.black54),
                          onPressed: () {
                            if (_points.length >= 0) {
                              setState(() {
                                int count = 50;
                                while (_points.isNotEmpty && count > 0) {
                                  _points.removeLast();
                                  count--;
                                }
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.download_rounded,
                              color: Colors.black54),
                          onPressed: () {
                            _saveImageToGallery(context);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.collections, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _points.clear();
                              _controller.clear();
                            });
                            _openImagePicker();
                          },
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

  void showSnackbar(BuildContext context, String message, int duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _saveImageToGallery(BuildContext context) async {
    if (_pickedImage != null) {
      try {
        // Get the directory for temporary files
        final Directory tempDir = await getTemporaryDirectory();

        // Read the image file as bytes
        Uint8List bytes = await _pickedImage!.readAsBytes();

        // Write the bytes to a temporary file
        final File tempFile = File('${tempDir.path}/temp_image.png');
        await tempFile.writeAsBytes(bytes);

        // Save the image to the gallery
        final result = await ImageGallerySaver.saveFile(tempFile.path);

        if (result['isSuccess']) {
          // Image saved successfully
          print('Image saved to gallery');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to gallery'),
              action: SnackBarAction(
                label: 'Close',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else {
          print('Failed to save image: ${result['errorMessage']}');
        }
      } catch (e) {
        print('Error saving image to gallery: $e');
      }
    }
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
        ..color = Colors.white
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 70.0;

      final croppedWidth = (containerBottomRightX - containerTopLeftX);
      final croppedHeight = (containerBottomRightY - containerTopLeftY);

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          if ((_points[i].dx >= containerTopLeftX &&
                  _points[i].dx <= containerBottomRightX &&
                  _points[i].dy >= containerTopLeftY &&
                  _points[i].dy <= containerBottomRightY) &&
              (_points[i + 1].dx >= containerTopLeftX &&
                  _points[i + 1].dx <= containerBottomRightX &&
                  _points[i + 1].dy >= containerTopLeftY &&
                  _points[i + 1].dy <= containerBottomRightY)) {
            Offset adjustedPoint1 = Offset(_points[i]!.dx - containerTopLeftX,
                _points[i]!.dy - containerTopLeftY);
            Offset adjustedPoint2 = Offset(
                _points[i + 1]!.dx - containerTopLeftX,
                _points[i + 1]!.dy - containerTopLeftY);
            canvas.drawLine(adjustedPoint1, adjustedPoint2, paint);
          }
        }
      }
      // Convert the image to a PNG byte array
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(croppedWidth.toInt(), croppedHeight.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngList = pngBytes!.buffer.asUint8List();

      final String filePath = _maskImagePath;

      File(filePath).writeAsBytesSync(pngList);
      print('file paadfdsfa $filePath');

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
