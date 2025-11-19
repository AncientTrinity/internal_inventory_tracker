// filename: lib/models/ticket.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Ticket {
  final int id;
  final String title;
  final String description;
  final String status; // OPEN, RECEIVED, IN_PROGRESS, RESOLVED, CLOSED
  final String type; // it_help, activation, deactivation, transition
  final String priority; // low, normal, high, critical
  final int createdBy;
  final int? assignedTo;
  final int? assetId;
  final double completion; // 0-100 percentage
  final bool isInternal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedToName;
  final String? assignedToEmail;
  final String? createdByName;
  final String? assetInternalId;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.type,
    required this.priority,
    required this.createdBy,
    this.assignedTo,
    this.assetId,
    required this.completion,
    required this.isInternal,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToName,
    this.assignedToEmail,
    this.createdByName,
    this.assetInternalId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
  // Convert status to uppercase for consistency in Flutter
  String status = json['status']?.toString().toUpperCase() ?? 'OPEN';
  
  // Handle the "in_progress" case specifically
  if (status == 'IN_PROGRESS') {
    status = 'IN_PROGRESS';
  } else if (status == 'OPEN') {
    status = 'OPEN';
  } else if (status == 'RECEIVED') {
    status = 'RECEIVED';
  } else if (status == 'RESOLVED') {
    status = 'RESOLVED';
  } else if (status == 'CLOSED') {
    status = 'CLOSED';
  }

  return Ticket(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    status: status,
    type: json['type'] ?? 'it_help',
    priority: json['priority'] ?? 'normal',
    createdBy: json['created_by'],
    assignedTo: json['assigned_to'],
    assetId: json['asset_id'],
    completion: (json['completion'] ?? 0.0).toDouble(),
    isInternal: json['is_internal'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
    assignedToName: json['assigned_to_user']?['full_name'],
    assignedToEmail: json['assigned_to_user']?['email'],
    createdByName: json['created_by_user']?['full_name'],
    assetInternalId: json['asset']?['internal_id'],
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

Map<String, dynamic> toStatusUpdateJson() {
  return {
    'status': status.toLowerCase(), // Send lowercase to Go API
    'completion': completion,
    'assigned_to': assignedTo,
  };
}

  // Helper methods
  bool get isOpen => status == 'OPEN';
  bool get isReceived => status == 'RECEIVED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';

  bool get isAssigned => assignedTo != null;

  String get statusDisplay {
    switch (status) {
      case 'OPEN': return 'Open';
      case 'RECEIVED': return 'Received';
      case 'IN_PROGRESS': return 'In Progress';
      case 'RESOLVED': return 'Resolved';
      case 'CLOSED': return 'Closed';
      default: return status;
    }
  }

  String get typeDisplay {
    switch (type) {
      case 'it_help': return 'IT Help';
      case 'activation': return 'Activation';
      case 'deactivation': return 'Deactivation';
      case 'transition': return 'Transition';
      default: return type;
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

  Color get statusColor {
    switch (status) {
      case 'OPEN': return Colors.orange;
      case 'RECEIVED': return Colors.blue;
      case 'IN_PROGRESS': return Colors.purple;
      case 'RESOLVED': return Colors.green;
      case 'CLOSED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low': return Colors.green;
      case 'normal': return Colors.blue;
      case 'high': return Colors.orange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('MMM dd, yyyy HH:mm').format(updatedAt);
  }
}

class TicketComment {
  final int id;
  final int ticketId;
  final int userId;
  final String comment;
  final bool isInternal;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.comment,
    required this.isInternal,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      comment: json['comment'],
      isInternal: json['is_internal'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'is_internal': isInternal,
    };
  }

  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
  }

  String get userDisplayName => userName ?? 'User $userId';
}