class AssetServiceLog {
  final int id;
  final int assetId;
  final int? performedBy;
  final DateTime performedAt;
  final String serviceType;
  final DateTime? nextServiceDate;
  final String notes;
  final DateTime createdAt;

  final String? performedByName;

  AssetServiceLog({
    required this.id,
    required this.assetId,
    this.performedBy,
    required this.performedAt,
    required this.serviceType,
    this.nextServiceDate,
    required this.notes,
    required this.createdAt,
    this.performedByName,
  });

  factory AssetServiceLog.fromJson(Map<String, dynamic> json) {
    return AssetServiceLog(
      id: json['id'],
      assetId: json['asset_id'],
      performedBy: json['performed_by'],
      performedAt: DateTime.parse(json['performed_at']),
      serviceType: json['service_type'],
      nextServiceDate: json['next_service_date'] != null 
          ? DateTime.parse(json['next_service_date']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      performedByName: json['performed_by_user']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'performed_by': performedBy,
      'performed_at': performedAt.toIso8601String().split('T')[0],
      'service_type': serviceType,
      'next_service_date': nextServiceDate?.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }

  String get serviceTypeDisplay {
    switch (serviceType) {
      case 'MAINTENANCE': return 'Maintenance';
      case 'REPAIR': return 'Repair';
      case 'UPGRADE': return 'Upgrade';
      default: return serviceType;
    }
  }

  IconData get serviceTypeIcon {
    switch (serviceType) {
      case 'MAINTENANCE': return Icons.build;
      case 'REPAIR': return Icons.handyman;
      case 'UPGRADE': return Icons.upgrade;
      default: return Icons.settings;
    }
  }
}