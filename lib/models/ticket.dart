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
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at']) 
          : null,
    );
  }

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
}