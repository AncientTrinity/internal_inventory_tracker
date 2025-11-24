// filename: lib/models/notification.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class Notification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final int? relatedId;
  final String? relatedType;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    required this.createdAt,
  });


Notification copyWith({
  int? id,
  int? userId,
  String? title,
  String? message,
  String? type,
  int? relatedId,
  String? relatedType,
  bool? isRead,
  DateTime? createdAt,
}) {
  return Notification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    message: message ?? this.message,
    type: type ?? this.type,
    relatedId: relatedId ?? this.relatedId,
    relatedType: relatedType ?? this.relatedType,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
}



  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get icon {
    switch (type) {
      case 'ticket_created':
        return '🎫';
      case 'ticket_updated':
        return '📝';
      case 'ticket_assigned':
        return '👤';
      case 'verification_requested':
        return '✅';
      case 'verification_completed':
        return '🔍';
      case 'asset_created':
        return '💻';
      case 'user_created':
        return '👥';
      default:
        return '🔔';
    }
  }

  Color get color {
    switch (type) {
      case 'ticket_created':
      case 'asset_created':
      case 'user_created':
        return Colors.blue;
      case 'ticket_updated':
      case 'ticket_assigned':
        return Colors.orange;
      case 'verification_requested':
      case 'verification_completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get actionableIcon {
  if (relatedId != null && relatedType != null) {
    switch (relatedType) {
      case 'ticket':
        return '🎫'; // Ticket with navigation
      case 'asset':
        return '💻'; // Computer with navigation
      case 'user':
        return '👤'; // User with navigation
      default:
        return '🔔'; // Regular bell
    }
  }
  return icon; // Fall back to regular icon
}

// Add a getter to show if notification is actionable
bool get isActionable => relatedId != null && relatedType != null;
}