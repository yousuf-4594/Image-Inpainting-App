// import 'dart:async';

// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// import 'package:path_provider/path_provider.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Image Drawing App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: ImageDrawingScreen(),
//     );
//   }
// }

// class ImageDrawingScreen extends StatefulWidget {
//   @override
//   _ImageDrawingScreenState createState() => _ImageDrawingScreenState();
// }

// class _ImageDrawingScreenState extends State<ImageDrawingScreen> {
//   late ui.Image _image;
//   late GlobalKey _repaintBoundaryKey;
//   late GlobalKey _paintKey;
//   late File _savedImage;
//   bool _isImageLoaded = false;
//   List<Offset> _points = [];

//   @override
//   void initState() {
//     super.initState();
//     _repaintBoundaryKey = GlobalKey();
//     _paintKey = GlobalKey();
//     _loadImage();
//   }

//   Future<void> _loadImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       final File imageFile = File(pickedFile.path);
//       final Uint8List bytes = await imageFile.readAsBytes();
//       final ui.Codec codec = await ui.instantiateImageCodec(bytes);
//       final ui.FrameInfo frameInfo = await codec.getNextFrame();
//       _image = frameInfo.image;
//       setState(() {
//         _isImageLoaded = true;
//       });
//     }
//   }

//   Future<void> _saveImage() async {
//     final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
//         .findRenderObject()! as RenderRepaintBoundary;
//     final ui.Image image = await boundary.toImage();
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List pngBytes = byteData!.buffer.asUint8List();

//     final String dir = (await getExternalStorageDirectory())!.path;
//     final String fileName = 'drawn_image.png';
//     final File imageFile = File('$dir/$fileName');
//     await imageFile.writeAsBytes(pngBytes);
//     setState(() {
//       _savedImage = imageFile;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Image saved successfully!'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }

//   void draw(Offset point) {
//     setState(() {
//       _points = List.from(_points)..add(point);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Image Drawing App'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _saveImage,
//           ),
//         ],
//       ),
//       body: _isImageLoaded
//           ? Center(
//               child: RepaintBoundary(
//                 key: _repaintBoundaryKey,
//                 child: GestureDetector(
//                   onPanUpdate: (details) {
//                     RenderBox renderBox =
//                         context.findRenderObject() as RenderBox;
//                     Offset localPosition =
//                         renderBox.globalToLocal(details.globalPosition);
//                     draw(localPosition);
//                   },
//                   child: AspectRatio(
//                     aspectRatio: _image.width / _image.height,
//                     child: CustomPaint(
//                       key: _paintKey,
//                       painter: ImageEditor(
//                         image: _image,
//                         points: _points,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           : Center(
//               child: CircularProgressIndicator(),
//             ),
//     );
//   }
// }

// class ImageEditor extends CustomPainter {
//   final ui.Image image;
//   final List<Offset> points;

//   ImageEditor({required this.image, required this.points});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint imagePaint = Paint();
//     canvas.drawImage(image, Offset.zero, imagePaint);

//     final Paint paint = Paint()
//       ..color = Colors.blue
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 30.0;

//     for (int i = 0; i < points.length - 1; i++) {
//       if (points[i] != null && points[i + 1] != null) {
//         canvas.drawLine(points[i], points[i + 1], paint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }
