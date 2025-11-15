class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final int roleId;
  final DateTime createdAt;
  final String? roleName;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.roleId,
    required this.createdAt,
    this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      email: json['email'],
      roleId: json['role_id'],
      createdAt: DateTime.parse(json['created_at']),
      roleName: json['role_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'full_name': fullName,
      'email': email,
      'role_id': roleId,
    };
  }

  String get roleDisplay {
    switch (roleId) {
      case 1: return 'Admin';
      case 2: return 'IT Staff';
      case 3: return 'Staff/Team Lead';
      case 4: return 'Agent';
      case 5: return 'Viewer';
      default: return 'Unknown';
    }
  }

  bool get isAdmin => roleId == 1;
  bool get isITStaff => roleId == 2;
  bool get isStaff => roleId == 3;
  bool get isAgent => roleId == 4;
  bool get isViewer => roleId == 5;

  bool get canManageUsers => isAdmin;
  bool get canManageAssets => isAdmin || isITStaff;
  bool get canManageTickets => isAdmin || isITStaff || isStaff;
  bool get canViewTickets => isAdmin || isITStaff || isStaff || isAgent || isViewer;
}