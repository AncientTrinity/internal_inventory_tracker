class TicketComment {
  final int id;
  final int ticketId;
  final int? authorId;
  final String comment;
  final bool isInternal;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? authorName;
  final String? authorUsername;

  TicketComment({
    required this.id,
    required this.ticketId,
    this.authorId,
    required this.comment,
    required this.isInternal,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorUsername,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'],
      ticketId: json['ticket_id'],
      authorId: json['author_id'],
      comment: json['comment'],
      isInternal: json['is_internal'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorName: json['author']?['full_name'],
      authorUsername: json['author']?['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'comment': comment,
      'is_internal': isInternal,
    };
  }

  String get authorDisplayName {
    return authorName ?? authorUsername ?? 'Unknown User';
  }

  bool get canEdit => true; // You can add logic based on user permissions
}