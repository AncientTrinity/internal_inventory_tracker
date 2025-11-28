//filename: lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/auth.dart';
import '../utils/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final request = LoginRequest(email: email, password: password);

    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return LoginResponse.fromJson(jsonResponse);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<LoginResponse> refreshToken(String token) async {
    final url = Uri.parse('$baseUrl/refresh');
    
    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'token': token}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return LoginResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Token refresh failed');
    }
  }

  // NOTE: getCurrentUser method is removed since the endpoint doesn't exist yet
  // We'll add it back when we implement the /me endpoint in the backend
}