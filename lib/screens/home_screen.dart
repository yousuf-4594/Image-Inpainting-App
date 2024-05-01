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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    fetchImages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchImages() async {
    print("is loading2: ${isLoading}");
    final String apiKey = '9AcoA5hSWNzpZyfKXvVQsXuqjV1Pmk8q7_5vq7ZtUIE';
    final String query = 'house interior';
    final String apiUrl =
        'https://api.unsplash.com/photos/random?count=15&query=$query&client_id=$apiKey';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        imageUrls = jsonResponse
            .map((photo) => photo['urls']['regular'] as String)
            .toList();
        isLoading = false;
      });
    } else {
      print("error");
      throw Exception('Failed to load images');
    }
    print("is loading3: ${isLoading}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Random().nextBool() ? 2 : 3,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              print("is loading: ${isLoading}");
              return isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    )
                  : Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                    );
            },
          ),
        ],
      ),
    );
  }
}
