class Role {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }

  String get displayName {
    switch (name) {
      case 'admin': return 'Administrator';
      case 'it': return 'IT Staff';
      case 'staff': return 'Staff/Team Lead';
      case 'agent': return 'Agent';
      case 'viewer': return 'Viewer';
      default: return name;
    }
  }
}