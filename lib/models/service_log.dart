// filename: lib/models/service_log.dart
import 'package:flutter/material.dart';

class ServiceLog {
  final int id;
  final int assetId;
  final String serviceType;
  final String description;
  final DateTime serviceDate;
  final String performedBy;
  final double? cost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceLog({
    required this.id,
    required this.assetId,
    required this.serviceType,
    required this.description,
    required this.serviceDate,
    required this.performedBy,
    this.cost,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    return ServiceLog(
      id: json['id'],
      assetId: json['asset_id'],
      serviceType: json['service_type'],
      description: json['description'],
      serviceDate: DateTime.parse(json['service_date']),
      performedBy: json['performed_by'],
      cost: json['cost'] != null ? double.parse(json['cost'].toString()) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'service_type': serviceType,
      'description': description,
      'service_date': _formatDateForApi(serviceDate),
      'performed_by': performedBy,
      'cost': cost,
      'notes': notes,
    };
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper methods
  bool get isPreventiveMaintenance => serviceType == 'PREVENTIVE_MAINTENANCE';
  bool get isRepair => serviceType == 'REPAIR';
  bool get isInspection => serviceType == 'INSPECTION';
  bool get isCalibration => serviceType == 'CALIBRATION';

  String get serviceTypeDisplay {
    switch (serviceType) {
      case 'PREVENTIVE_MAINTENANCE': return 'Preventive Maintenance';
      case 'REPAIR': return 'Repair';
      case 'INSPECTION': return 'Inspection';
      case 'CALIBRATION': return 'Calibration';
      default: return serviceType;
    }
  }

  Color get serviceTypeColor {
    switch (serviceType) {
      case 'PREVENTIVE_MAINTENANCE': return Colors.green;
      case 'REPAIR': return Colors.orange;
      case 'INSPECTION': return Colors.blue;
      case 'CALIBRATION': return Colors.purple;
      default: return Colors.grey;
    }
  }
}