import 'package:flutter/material.dart';
import 'package:image_inpainting/screens/ai_screen.dart';
import 'package:image_inpainting/screens/home_screen.dart';
import 'package:image_inpainting/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_inpainting/utils/shared_variables.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
      bottomNavigationBar: navbar_widget(),
    );
    return ChangeNotifierProvider(create: (context) => SharedVariables(), child: MaterialApp(home: scaffold),);
  }

  BottomNavigationBar navbar_widget() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_b_and_w_rounded),
          label: '',
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
