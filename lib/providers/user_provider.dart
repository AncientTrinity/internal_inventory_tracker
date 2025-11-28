// filename: lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers(String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      _users = await _userService.getUsers(token);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  
  Future<User> getUserById(int userId, String token) async {
    try {
      return await _userService.getUserById(userId, token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  List<User> getITStaff() {
    return _users.where((user) => user.isITStaff || user.isAdmin).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> createUser(Map<String, dynamic> userData, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      final newUser = await _userService.createUser(userData, token);
      _users.add(newUser);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> updateUser(int userId, Map<String, dynamic> userData, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      final updatedUser = await _userService.updateUser(userId, userData, token);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> deleteUser(int userId, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      await _userService.deleteUser(userId, token);
      _users.removeWhere((user) => user.id == userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> sendCredentials(int userId, String token) async {
    try {
      await _userService.sendCredentials(userId, token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }


Future<void> sendPasswordChangeEmail(int userId, String password, String token) async {
  try {
    await _userService.sendPasswordChangeEmail(userId, password, token);
  } catch (e) {
    _error = e.toString();
    rethrow;
  }
}

  Future<void> resetPassword(int userId, String newPassword, bool sendEmail, String token) async {
    try {
      await _userService.resetPassword(userId, newPassword, sendEmail, token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}