import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class TestService {
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/healthcheck');
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}