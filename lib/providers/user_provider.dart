import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  List<Role> _roles = [];
  User? _selectedUser;
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  List<Role> get roles => _roles;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/users');
      _users = (response as List).map((json) => User.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load users: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRoles() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/roles');
      _roles = (response as List).map((json) => Role.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load roles: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> getUserById(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/users/$id');
      _selectedUser = User.fromJson(response);
      notifyListeners();
      return _selectedUser;
    } catch (e) {
      _error = 'Failed to load user: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUser(User user) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.post('/users', user.toJson());
      final newUser = User.fromJson(response);
      _users.add(newUser);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create user: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUser(User user) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.put('/users/${user.id}', user.toJson());
      final updatedUser = User.fromJson(response);
      
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      if (_selectedUser?.id == user.id) {
        _selectedUser = updatedUser;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update user: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteUser(int userId) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.delete('/users/$userId');
      _users.removeWhere((user) => user.id == userId);
      
      if (_selectedUser?.id == userId) {
        _selectedUser = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<User> getUsersByRole(int roleId) {
    return _users.where((user) => user.roleId == roleId).toList();
  }

  List<User> getITStaff() {
    return getUsersByRole(2); // IT Staff role ID
  }

  List<User> getStaff() {
    return getUsersByRole(3); // Staff/Team Lead role ID
  }

  List<User> getAgents() {
    return getUsersByRole(4); // Agent role ID
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedUser = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}