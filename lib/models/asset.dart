// filename: lib/models/asset.dart
import 'package:flutter/material.dart';

class Asset {
  final int id;
  final String internalId;
  final String assetType;
  final String manufacturer;
  final String model;
  final String modelNumber;
  final String serialNumber;
  final String status;
  final int? inUseBy;
  final DateTime? datePurchased;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields for display
  final String? assignedToName;
  final String? assignedToEmail;

  Asset({
    required this.id,
    required this.internalId,
    required this.assetType,
    required this.manufacturer,
    required this.model,
    required this.modelNumber,
    required this.serialNumber,
    required this.status,
    this.inUseBy,
    this.datePurchased,
    this.lastServiceDate,
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToName,
    this.assignedToEmail,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      internalId: json['internal_id'],
      assetType: json['asset_type'],
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      modelNumber: json['model_number'] ?? '',
      serialNumber: json['serial_number'] ?? '',
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
      assignedToName: json['assigned_to_name'],
      assignedToEmail: json['assigned_to_email'],
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
      'date_purchased': datePurchased?.toIso8601String(),
      'last_service_date': lastServiceDate?.toIso8601String(),
      'next_service_date': nextServiceDate?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAssigned => inUseBy != null;
  bool get needsService => nextServiceDate != null &&
      nextServiceDate!.isBefore(DateTime.now());
  bool get isInUse => status == 'IN_USE';
  bool get isInStorage => status == 'IN_STORAGE';
  bool get isInRepair => status == 'REPAIR';
  bool get isRetired => status == 'RETIRED';

  String get statusDisplay {
    switch (status) {
      case 'IN_USE': return 'In Use';
      case 'IN_STORAGE': return 'In Storage';
      case 'REPAIR': return 'In Repair';
      case 'RETIRED': return 'Retired';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'IN_USE': return Colors.green;
      case 'IN_STORAGE': return Colors.blue;
      case 'REPAIR': return Colors.orange;
      case 'RETIRED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get typeDisplay {
    switch (assetType) {
      case 'PC': return 'Computer';
      case 'MONITOR': return 'Monitor';
      case 'KEYBOARD': return 'Keyboard';
      case 'MOUSE': return 'Mouse';
      case 'HEADSET': return 'Headset';
      case 'UPS': return 'UPS';
      default: return assetType;
    }
  }

  // CopyWith method
  Asset copyWith({
    int? id,
    String? internalId,
    String? assetType,
    String? manufacturer,
    String? model,
    String? modelNumber,
    String? serialNumber,
    String? status,
    int? inUseBy,
    DateTime? datePurchased,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    String? assignedToName,
    String? assignedToEmail,
  }) {
    return Asset(
      id: id ?? this.id,
      internalId: internalId ?? this.internalId,
      assetType: assetType ?? this.assetType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      inUseBy: inUseBy ?? this.inUseBy,
      datePurchased: datePurchased ?? this.datePurchased,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
    );
  }
}

// Asset filters for search
class AssetFilters {
  final String? searchQuery;
  final String? assetType;
  final String? status;
  final String? manufacturer;
  final int? inUseBy;
  final bool? needsService;
  final String? assignmentStatus; // 'assigned' or 'unassigned'

  AssetFilters({
    this.searchQuery,
    this.assetType,
    this.status,
    this.manufacturer,
    this.inUseBy,
    this.needsService,
    this.assignmentStatus,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['q'] = searchQuery!;
    }
    if (assetType != null && assetType!.isNotEmpty) {
      params['type'] = assetType!;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status!;
    }
    if (manufacturer != null && manufacturer!.isNotEmpty) {
      params['manufacturer'] = manufacturer!;
    }
    if (inUseBy != null) {
      params['in_use_by'] = inUseBy.toString();
    }
    if (needsService == true) {
      params['needs_service'] = 'true';
    }
    if (assignmentStatus != null) {
      params['assignment_status'] = assignmentStatus!;
    }

    return params;
  }

  AssetFilters copyWith({
    String? searchQuery,
    String? assetType,
    String? status,
    String? manufacturer,
    int? inUseBy,
    bool? needsService,
    String? assignmentStatus,
  }) {
    return AssetFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      manufacturer: manufacturer ?? this.manufacturer,
      inUseBy: inUseBy ?? this.inUseBy,
      needsService: needsService ?? this.needsService,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
    );
  }
}