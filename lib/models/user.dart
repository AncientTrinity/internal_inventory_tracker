//filename: lib/models/user.dart
class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final int roleId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.roleId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      email: json['email'],
      roleId: json['role_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get roleName {
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

  //Permission checks
  bool get canCreateTickets => isAdmin || isITStaff || isStaff;
  bool get canAssignTickets => isAdmin || isITStaff;
  bool get canViewAllTickets => isAdmin || isITStaff || isStaff;
  bool get canEditTickets => isAdmin || isITStaff;
  bool get canDeleteTickets => isAdmin || isITStaff;

}