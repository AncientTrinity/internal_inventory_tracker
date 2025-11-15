class Permission {
  final int id;
  final String name;
  final String resource;
  final String action;
  final String? description;

  Permission({
    required this.id,
    required this.name,
    required this.resource,
    required this.action,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'],
      name: json['name'],
      resource: json['resource'],
      action: json['action'],
      description: json['description'],
    );
  }

  String get displayName {
    final resourceName = resource.replaceAll('_', ' ').titleCase;
    final actionName = action.replaceAll('_', ' ').titleCase;
    return '$actionName $resourceName';
  }
}

// Extension for string title case
extension StringExtensions on String {
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}