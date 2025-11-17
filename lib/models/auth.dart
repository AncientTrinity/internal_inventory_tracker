//filename: lib/models/auth.dart
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final int userId;
  final int roleId;
  final String email;

  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.roleId,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      expiresAt: DateTime.parse(json['expires_at']),
      userId: json['user_id'],
      roleId: json['role_id'],
      email: json['email'],
    );
  }
}

class AuthData {
  final String token;
  final DateTime expiresAt;
  final int userId;
  final int roleId;
  final String email;

  AuthData({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.roleId,
    required this.email,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}