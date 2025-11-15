import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await AuthService.login(email, password);
      if (success) {
        await _fetchCurrentUser();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        await _fetchCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      // Get current user info - you might need to create this endpoint
      final response = await ApiService.get('/users/me');
      _user = User.fromJson(response);
    } catch (e) {
      _error = 'Failed to fetch user data: $e';
      // If we can't get user data, log out
      await logout();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check permissions based on user role
  bool get canManageUsers => _user?.isAdmin ?? false;
  bool get canManageAssets => _user?.canManageAssets ?? false;
  bool get canManageTickets => _user?.canManageTickets ?? false;
  bool get canViewTickets => _user?.canViewTickets ?? false;
}