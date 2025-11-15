class Ticket {
  final int id;
  final String ticketNum;
  final String title;
  final String description;
  final String type;
  final String priority;
  final String status;
  final int completion;
  final int? createdBy;
  final int? assignedTo;
  final int? assetId;
  final bool isInternal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  final String? createdByName;
  final String? assignedToName;
  final String? assetName;

  Ticket({
    required this.id,
    required this.ticketNum,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.completion,
    this.createdBy,
    this.assignedTo,
    this.assetId,
    required this.isInternal,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.createdByName,
    this.assignedToName,
    this.assetName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketNum: json['ticket_num'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      priority: json['priority'],
      status: json['status'],
      completion: json['completion'],
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      assetId: json['asset_id'],
      isInternal: json['is_internal'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      createdByName: json['created_by_user']?['full_name'],
      assignedToName: json['assigned_to_user']?['full_name'],
      assetName: json['asset']?['internal_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'asset_id': assetId,
      'is_internal': isInternal,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'open': return 'Open';
      case 'received': return 'Received';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low': return 'Low';
      case 'normal': return 'Normal';
      case 'high': return 'High';
      case 'critical': return 'Critical';
      default: return priority;
    }
  }

  String get typeDisplay {
    switch (type) {
      case 'activation': return 'Activation';
      case 'deactivation': return 'Deactivation';
      case 'it_help': return 'IT Help';
      case 'transition': return 'Transition';
      default: return type;
    }
  }
}