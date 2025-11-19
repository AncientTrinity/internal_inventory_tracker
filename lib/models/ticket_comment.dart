// filename: lib/models/ticket_comment.dart
import 'package:intl/intl.dart';

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
    // Handle nested author structure from API
    final author = json['author'] as Map<String, dynamic>?;
    
    return TicketComment(
      id: json['id'] as int? ?? 0,
      ticketId: json['ticket_id'] as int? ?? 0,
      userId: json['author_id'] as int? ?? (json['user_id'] as int? ?? 0), // Handle both author_id and user_id
      comment: json['comment'] as String? ?? '',
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      userName: author?['full_name'] as String? ?? author?['username'] as String?,
      userEmail: author?['email'] as String?,
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