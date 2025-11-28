// filename: lib/models/report.dart
class ReportData {
  final Map<String, dynamic> ticketStats;
  final Map<String, dynamic> assetStats;
  final List<Map<String, dynamic>> ticketTrends;
  final List<Map<String, dynamic>> assetUtilization;
  final List<Map<String, dynamic>> userActivity;

  ReportData({
    required this.ticketStats,
    required this.assetStats,
    required this.ticketTrends,
    required this.assetUtilization,
    required this.userActivity,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      ticketStats: Map<String, dynamic>.from(json['ticket_stats'] ?? {}),
      assetStats: Map<String, dynamic>.from(json['asset_stats'] ?? {}),
      ticketTrends: List<Map<String, dynamic>>.from(json['ticket_trends'] ?? []),
      assetUtilization: List<Map<String, dynamic>>.from(json['asset_utilization'] ?? []),
      userActivity: List<Map<String, dynamic>>.from(json['user_activity'] ?? []),
    );
  }
}

class ReportFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String? assetType;
  final String? ticketType;
  final int? userId;
  final String? priority;

  ReportFilter({
    required this.startDate,
    required this.endDate,
    this.assetType,
    this.ticketType,
    this.userId,
    this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      // Fix: Use proper ISO format without milliseconds
      'start_date': _formatDateForApi(startDate),
      'end_date': _formatDateForApi(endDate),
      'asset_type': assetType,
      'ticket_type': ticketType,
      'user_id': userId,
      'priority': priority,
    };
  }

  // Helper method to format dates for API
  String _formatDateForApi(DateTime date) {
    // Format: YYYY-MM-DDTHH:MM:SSZ (ISO 8601 without milliseconds)
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    
    return '${year}-${month}-${day}T${hour}:${minute}:${second}Z';
  }

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? assetType,
    String? ticketType,
    int? userId,
    String? priority,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assetType: assetType ?? this.assetType,
      ticketType: ticketType ?? this.ticketType,
      userId: userId ?? this.userId,
      priority: priority ?? this.priority,
    );
  }
}

// Extension for string formatting
extension StringCasingExtension on String {
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '')
      .join(' ');
}