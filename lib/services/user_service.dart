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

// Create user
Future<User> createUser(Map<String, dynamic> userData, String token) async {
  try {
    print('📡 Creating user: ${userData['username']}');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/users'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return User.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to create user: $e');
    throw Exception('Failed to create user: $e');
  }
}

// Update user
Future<User> updateUser(int userId, Map<String, dynamic> userData, String token) async {
  try {
    print('📡 Updating user $userId');
    
    final response = await http.put(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return User.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to update user: $e');
    throw Exception('Failed to update user: $e');
  }
}

// Delete user
Future<void> deleteUser(int userId, String token) async {
  try {
    print('📡 Deleting user $userId');
    
    final response = await http.delete(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ User deleted successfully');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to delete user: $e');
    throw Exception('Failed to delete user: $e');
  }
}

// Send credentials
Future<void> sendCredentials(int userId, String token) async {
  try {
    print('📡 Sending credentials to user $userId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId/send-credentials'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Credentials sent successfully');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to send credentials: $e');
    throw Exception('Failed to send credentials: $e');
  }
}

// Reset password
 Future<void> resetPassword(int userId, String newPassword, bool sendEmail, String token) async {
  try {
    print('📡 Resetting password for user $userId');
    print('🔐 New password: $newPassword');
    print('📧 Send email: $sendEmail');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId/reset-password'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'new_password': newPassword,
        'send_email': sendEmail,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Password reset successfully');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to reset password: $e');
    throw Exception('Failed to reset password: $e');
  }
}

// Send password change email
Future<void> sendPasswordChangeEmail(int userId, String password, String token) async {
  try {
    print('📡 Sending password change email to user $userId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId/send-password-change'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Password change email sent successfully');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Failed to send password change email: $e');
    throw Exception('Failed to send password change email: $e');
  }
}

}