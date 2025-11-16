import 'package:flutter/foundation.dart';

import '../models/auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthData? _authData;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthData? get authData => _authData;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authData != null && !_authData!.isExpired;

  // Check existing authentication on app start
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
          
          // Create user from stored data (NO API CALL NEEDED)
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
          // Token expired, try to refresh
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

  // Login method
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

  // Handle successful login
  Future<void> _loginSuccess(LoginResponse response) async {
    _authData = AuthData(
      token: response.token,
      expiresAt: response.expiresAt,
      userId: response.userId,
      roleId: response.roleId,
      email: response.email,
    );

    // Save to secure storage
    await SecureStorageService.saveAuthData(
      token: response.token,
      userId: response.userId,
      roleId: response.roleId,
      email: response.email,
      expiresAt: response.expiresAt,
    );

    // Create user object from login response data (NO API CALL NEEDED)
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

  // Logout method
  Future<void> logout() async {
    await _logout();
  }

  Future<void> _logout() async {
    _authData = null;
    _currentUser = null;
    _error = null;
    
    await SecureStorageService.clearAuthData();
    
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh token if needed
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

  // Helper method to get default name based on role
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