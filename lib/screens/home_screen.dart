import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

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
      throw Exception('Failed to load images');
    }
    print("is loading: ${isLoading}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ListView(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
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
