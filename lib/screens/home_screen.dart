import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'dart:math';

class home_screen extends StatefulWidget {
  @override
  _home_screenState createState() => _home_screenState();
}

class _home_screenState extends State<home_screen> {
  List<String> imageUrls = [];
  bool isLoading = false;
  int page = 1;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchImages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      print(
          'req more images');
    }
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      fetchImages();
    }
  }

  String getRandomPrompt() {
    List<String> prompts = [
      "Living room design",
      "Room design trends",
      "Room paint design",
      "Interior room design",
      "Door design",
      "Kitchen design",
      "Room wall design",
      "Chair design",
      "Furniture design",
      "Room bookshelf design",
      "Bedroom design"
    ];

    int randomIndex = Random().nextInt(prompts.length);

    return prompts[randomIndex];
  }

  Future<void> fetchImages() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      final String apiKey = '9AcoA5hSWNzpZyfKXvVQsXuqjV1Pmk8q7_5vq7ZtUIE';
      final String query = getRandomPrompt();
      final String apiUrl =
          'https://api.unsplash.com/photos/random?count=15&page=$page&query=$query&client_id=$apiKey';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          imageUrls.addAll(jsonResponse
              .map((photo) => photo['urls']['regular'] as String)
              .toList());
          isLoading = false;
          page++;
        });
      } else {
        throw Exception('Failed to load images');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Discover'),
            Row(
              children: [
                Icon(Icons.search_rounded),
                SizedBox(width: 20),
                Icon(Icons.invert_colors_on_outlined),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
            ),
            itemCount: imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == imageUrls.length) {
                return Center(
                    child: Container(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 1,
                        )));
              } else {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
