class Asset {
  final int id;
  final String internalId;
  final String assetType;
  final String? manufacturer;
  final String? model;
  final String? modelNumber;
  final String? serialNumber;
  final String status;
  final int? inUseBy;
  final DateTime? datePurchased;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? assignedToName;
  final int? assignedToId;

  Asset({
    required this.id,
    required this.internalId,
    required this.assetType,
    this.manufacturer,
    this.model,
    this.modelNumber,
    this.serialNumber,
    required this.status,
    this.inUseBy,
    this.datePurchased,
    this.lastServiceDate,
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToName,
    this.assignedToId,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      internalId: json['internal_id'],
      assetType: json['asset_type'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      modelNumber: json['model_number'],
      serialNumber: json['serial_number'],
      status: json['status'],
      inUseBy: json['in_use_by'],
      datePurchased: json['date_purchased'] != null 
          ? DateTime.parse(json['date_purchased']) 
          : null,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date']) 
          : null,
      nextServiceDate: json['next_service_date'] != null 
          ? DateTime.parse(json['next_service_date']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      assignedToName: json['assigned_user']?['full_name'],
      assignedToId: json['in_use_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internal_id': internalId,
      'asset_type': assetType,
      'manufacturer': manufacturer,
      'model': model,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'status': status,
      'in_use_by': inUseBy,
      'date_purchased': datePurchased?.toIso8601String().split('T')[0],
      'last_service_date': lastServiceDate?.toIso8601String().split('T')[0],
      'next_service_date': nextServiceDate?.toIso8601String().split('T')[0],
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'IN_USE': return 'In Use';
      case 'IN_STORAGE': return 'In Storage';
      case 'RETIRED': return 'Retired';
      case 'REPAIR': return 'In Repair';
      default: return status;
    }
  }

  String get typeDisplay {
    switch (assetType) {
      case 'PC': return 'PC';
      case 'Monitor': return 'Monitor';
      case 'Keyboard': return 'Keyboard';
      case 'Mouse': return 'Mouse';
      case 'Headset': return 'Headset';
      case 'UPS': return 'UPS';
      default: return assetType;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'IN_USE': return Colors.green;
      case 'IN_STORAGE': return Colors.blue;
      case 'RETIRED': return Colors.grey;
      case 'REPAIR': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (assetType) {
      case 'PC': return Icons.computer;
      case 'Monitor': return Icons.desktop_windows;
      case 'Keyboard': return Icons.keyboard;
      case 'Mouse': return Icons.mouse;
      case 'Headset': return Icons.headset;
      case 'UPS': return Icons.power;
      default: return Icons.devices_other;
    }
  }

  bool get isAssigned => inUseBy != null;
  bool get needsService {
    if (nextServiceDate == null) return false;
    return nextServiceDate!.isBefore(DateTime.now());
  }
}