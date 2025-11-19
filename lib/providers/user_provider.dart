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

  List<User> getITStaff() {
    return _users.where((user) => user.isITStaff || user.isAdmin).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}