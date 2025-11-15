class TicketStats {
  final int total;
  final int open;
  final int received;
  final int inProgress;
  final int resolved;
  final int closed;
  final int critical;

  TicketStats({
    required this.total,
    required this.open,
    required this.received,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.critical,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) {
    return TicketStats(
      total: json['total'],
      open: json['open'],
      received: json['received'],
      inProgress: json['in_progress'],
      resolved: json['resolved'],
      closed: json['closed'],
      critical: json['critical'],
    );
  }

  int get activeTickets => open + received + inProgress;
  double get completionRate => total > 0 ? closed / total : 0;
}