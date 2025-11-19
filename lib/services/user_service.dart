// filename: lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/api_config.dart';

class UserService {
  
  dynamic _handleResponse(http.Response response) {
    print('🔍 User Response - Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseBody = json.decode(response.body);
        
        if (responseBody is List) {
          return responseBody;
        } else if (responseBody is Map) {
          return responseBody['data'] ?? responseBody['users'] ?? responseBody;
        } else {
          return responseBody;
        }
      } catch (e) {
        print('❌ JSON decode error: $e');
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Get all users
  Future<List<User>> getUsers(String token) async {
    try {
      print('📡 Fetching users');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/users'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      List<dynamic> usersList;
      
      if (responseData is List) {
        usersList = responseData;
      } else if (responseData is Map && responseData.containsKey('users')) {
        usersList = responseData['users'];
      } else {
        usersList = [responseData];
      }
      
      print('📦 Parsed ${usersList.length} users');
      return usersList.map<User>((user) {
        return User.fromJson(Map<String, dynamic>.from(user));
      }).toList();
    } catch (e) {
      print('❌ Failed to load users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  // Get IT staff users (for assignment)
  Future<List<User>> getITStaff(String token) async {
    try {
      final allUsers = await getUsers(token);
      return allUsers.where((user) => user.isAdmin || user.isITStaff).toList();
    } catch (e) {
      print('❌ Failed to load IT staff: $e');
      throw Exception('Failed to load IT staff: $e');
    }
  }

  // Get user by ID
  Future<User> getUserById(int userId, String token) async {
    try {
      print('📡 Fetching user $userId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        return User.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to load user: $e');
      throw Exception('Failed to load user: $e');
    }
  }
}