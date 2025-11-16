import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRoleId = 'role_id';
  static const _keyEmail = 'email';
  static const _keyExpiresAt = 'expires_at';

  // Save authentication data
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required int roleId,
    required String email,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyRoleId, value: roleId.toString());
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
  }

  // Get authentication data
  static Future<Map<String, String?>> getAuthData() async {
    final token = await _storage.read(key: _keyToken);
    final userId = await _storage.read(key: _keyUserId);
    final roleId = await _storage.read(key: _keyRoleId);
    final email = await _storage.read(key: _keyEmail);
    final expiresAt = await _storage.read(key: _keyExpiresAt);

    return {
      'token': token,
      'userId': userId,
      'roleId': roleId,
      'email': email,
      'expiresAt': expiresAt,
    };
  }

  // Clear authentication data (logout)
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyRoleId);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyExpiresAt);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyToken);
    final expiresAt = await _storage.read(key: _keyExpiresAt);
    
    if (token == null || expiresAt == null) {
      return false;
    }

    final expiryDate = DateTime.parse(expiresAt);
    return expiryDate.isAfter(DateTime.now());
  }
}