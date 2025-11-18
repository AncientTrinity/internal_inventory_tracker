// filename: lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/api_config.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthData? _authData;
  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _loadingUsers = false;

  AuthData? get authData => _authData;
  User? get currentUser => _currentUser;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get loadingUsers => _loadingUsers;
  String? get error => _error;
  bool get isLoggedIn => _authData != null && !_authData!.isExpired;

  // Load all users for assignment (requires users:read permission)
  Future<void> loadUsers() async {
    if (!isLoggedIn) {
      throw Exception('Not authenticated');
    }

    _loadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      final token = _authData!.token;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 Users API Response: ${response.statusCode}');
      print('🔍 Users API URL: ${ApiConfig.apiBaseUrl}/users');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('🔍 Users Response Data Type: ${responseData.runtimeType}');
        
        List<dynamic> usersList;
        
        // Handle the response format - it's a raw array based on your curl test
        if (responseData is List) {
          // This is what your API returns - direct array
          print('✅ API returns raw array format');
          usersList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Some APIs wrap in { "data": [...] }
          print('✅ API returns wrapped data format');
          usersList = responseData['data'];
        } else if (responseData is Map && responseData.containsKey('users')) {
          // Some APIs wrap in { "users": [...] }
          print('✅ API returns wrapped users format');
          usersList = responseData['users'];
        } else {
          // Fallback
          print('⚠️ Unknown response format, trying to handle as array');
          usersList = responseData is List ? responseData : [responseData];
        }
        
        print('🔍 Parsed users list length: ${usersList.length}');
        
        // Convert to User objects
        _users = usersList.map((userData) {
          print('🔍 Processing user data: $userData');
          try {
            return User.fromJson(userData);
          } catch (e) {
            print('❌ Error parsing user: $userData, error: $e');
            rethrow;
          }
        }).toList();
        
        _error = null;
        
        print('✅ Successfully loaded ${_users.length} users');
        for (final user in _users) {
          print('   👤 ${user.fullName} (${user.email}) - Role: ${user.roleName}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: You need users:read permission to access user list');
      } else {
        throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading users: $e');
      rethrow;
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  // Get user by ID
  User? getUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear users list
  void _clearUsers() {
    _users = [];
  }

  // Existing methods with user management integration
  Future<bool> checkExistingAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedAuth = await SecureStorageService.getAuthData();
      
      if (storedAuth['token'] != null && storedAuth['expiresAt'] != null) {
        final expiresAt = DateTime.parse(storedAuth['expiresAt']!);
        
        if (expiresAt.isAfter(DateTime.now())) {
          _authData = AuthData(
            token: storedAuth['token']!,
            expiresAt: expiresAt,
            userId: int.parse(storedAuth['userId']!),
            roleId: int.parse(storedAuth['roleId']!),
            email: storedAuth['email']!,
          );
          
          _currentUser = User(
            id: int.parse(storedAuth['userId']!),
            username: storedAuth['email']!.split('@').first,
            fullName: _getDefaultName(int.parse(storedAuth['roleId']!)),
            email: storedAuth['email']!,
            roleId: int.parse(storedAuth['roleId']!),
            createdAt: DateTime.now(),
          );
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          try {
            final newAuth = await _authService.refreshToken(storedAuth['token']!);
            await _loginSuccess(newAuth);
            return true;
          } catch (e) {
            await _logout();
            return false;
          }
        }
      }
    } catch (e) {
      print('Auth check error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      await _loginSuccess(response);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loginSuccess(LoginResponse response) async {
    _authData = AuthData(
      token: response.token,
      expiresAt: response.expiresAt,
      userId: response.userId,
      roleId: response.roleId,
      email: response.email,
    );

    await SecureStorageService.saveAuthData(
      token: response.token,
      userId: response.userId,
      roleId: response.roleId,
      email: response.email,
      expiresAt: response.expiresAt,
    );

    _currentUser = User(
      id: response.userId,
      username: response.email.split('@').first,
      fullName: _getDefaultName(response.roleId),
      email: response.email,
      roleId: response.roleId,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _logout();
  }

  Future<void> _logout() async {
    _authData = null;
    _currentUser = null;
    _error = null;
    _clearUsers();
    
    await SecureStorageService.clearAuthData();
    
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> refreshTokenIfNeeded() async {
    if (_authData != null && _authData!.isExpired) {
      try {
        final newAuth = await _authService.refreshToken(_authData!.token);
        await _loginSuccess(newAuth);
        return true;
      } catch (e) {
        await _logout();
        return false;
      }
    }
    return true;
  }

  String _getDefaultName(int roleId) {
    switch (roleId) {
      case 1: return 'System Administrator';
      case 2: return 'IT Support Staff';
      case 3: return 'Team Lead';
      case 4: return 'Call Center Agent';
      case 5: return 'Viewer';
      default: return 'User';
    }
  }
}