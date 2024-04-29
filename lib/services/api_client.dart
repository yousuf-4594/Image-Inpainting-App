import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const String _baseUrl = 'https://wicked-walls-unite.loca.lt';

  static Future<dynamic> fetchData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        print(response.body);
        return jsonDecode(response.body);
      } else {
        // If the server returns an error response, throw an exception
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // If an error occurs during the HTTP request, throw an exception
      throw Exception('Failed to connect to the server');
    }
  }

  static Future<dynamic> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        return jsonDecode(response.body);
      } else {
        // If the server returns an error response, throw an exception
        throw Exception('Failed to post data');
      }
    } catch (e) {
      // If an error occurs during the HTTP request, throw an exception
      throw Exception('Failed to connect to the server');
    }
  }
}
