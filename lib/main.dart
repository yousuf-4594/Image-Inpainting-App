import 'package:flutter/material.dart';
import 'package:image_inpainting/screens/ai_screen.dart';
import 'package:image_inpainting/screens/home_screen.dart';
import 'package:image_inpainting/screens/settings_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
<<<<<<< HEAD
  File? _image;
  File? _maskImage;
  Image? _uploadedImage;
  // Image? _uploadedMaskImage;
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

  Future<void> _getMaskImage() async{
    final maskImagePicker = ImagePicker();
    final maskPickedFile = await maskImagePicker.pickImage(source: ImageSource.gallery);
    if (maskPickedFile != null) {
      setState(() {
        _maskImage = File(maskPickedFile.path);
      });
    }
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
=======
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
>>>>>>> 2f657d91706ca3b16d829334256a0c783078d4de
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          home_screen(),
          ai_screen(),
          settings_screen(),
        ],
      ),
<<<<<<< HEAD
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
                borderRadius: BorderRadius.circular(5.0), // Adjust border radius as needed
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
                borderRadius: BorderRadius.circular(5.0), // Adjust border radius as needed
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
              Container(width:150, height: 150, child: Image.file(_image!)),
              SizedBox(height: 20),
            ],
            if (_maskImage != null) ...[
              Container(width:150, height: 150, child: Image.file(_maskImage!)),
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
            if(_uploadedImage != null)...[
              SizedBox(height: 20,),
              Container(width: 250, height: 250, child: _uploadedImage!),

            ]
          ],
=======
      bottomNavigationBar: navbar_widget(),
    );
    return scaffold;
  }

  BottomNavigationBar navbar_widget() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_b_and_w_rounded),
          label: '',
>>>>>>> 2f657d91706ca3b16d829334256a0c783078d4de
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.blur_on_rounded),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_sharp),
          label: '',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }
}
