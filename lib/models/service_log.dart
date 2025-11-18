// filename: lib/models/service_log.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceLog {
  final int id;
  final int assetId;
  final String serviceType;
  final String description;
  final DateTime serviceDate;
  final int performedBy;
  final double? cost;
  final String? notes;
  final DateTime? nextServiceDate;
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
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    print('📦 Parsing ServiceLog JSON: $json');
    
    try {
      // Debug each field individually
      print('🔍 Field types:');
      print('  - id: ${json['id']} (${json['id'].runtimeType})');
      print('  - asset_id: ${json['asset_id']} (${json['asset_id'].runtimeType})');
      print('  - performed_by: ${json['performed_by']} (${json['performed_by'].runtimeType})');
      print('  - service_type: ${json['service_type']} (${json['service_type'].runtimeType})');
      print('  - performed_at: ${json['performed_at']} (${json['performed_at'].runtimeType})');
      print('  - notes: ${json['notes']} (${json['notes']?.runtimeType})');
      print('  - next_service_date: ${json['next_service_date']} (${json['next_service_date']?.runtimeType})');
      print('  - created_at: ${json['created_at']} (${json['created_at'].runtimeType})');

      // Handle description - it might be missing from API response
      String description;
      if (json.containsKey('description') && json['description'] != null) {
        description = json['description'].toString();
      } else {
        // Create a default description based on service type and date
        final date = DateTime.parse(json['performed_at']);
        final serviceType = json['service_type'] ?? 'SERVICE';
        description = '$serviceType performed on ${DateFormat('MMM dd, yyyy').format(date)}';
      }

      return ServiceLog(
        id: _parseInt(json['id']),
        assetId: _parseInt(json['asset_id']),
        serviceType: json['service_type']?.toString() ?? 'PREVENTIVE_MAINTENANCE',
        description: description,
        serviceDate: DateTime.parse(json['performed_at'].toString()),
        performedBy: _parseInt(json['performed_by']),
        cost: json['cost'] != null ? _parseDouble(json['cost']) : null,
        notes: json['notes']?.toString(),
        nextServiceDate: json['next_service_date'] != null 
            ? DateTime.parse(json['next_service_date'].toString())
            : null,
        createdAt: DateTime.parse(json['created_at'].toString()),
        updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']).toString()),
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing ServiceLog: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Problematic JSON: $json');
      rethrow;
    }
  }

  // Helper method to safely parse integers
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  // Helper method to safely parse doubles
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'service_type': serviceType,
      'description': description,
      'performed_by': performedBy,
      'cost': cost,
      'notes': notes,
      'next_service_date': nextServiceDate != null 
          ? _formatDateForApi(nextServiceDate!)
          : null,
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

  // Helper to check if next service is due soon
  bool get isNextServiceDueSoon {
    if (nextServiceDate == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return nextServiceDate!.isBefore(thirtyDaysFromNow);
  }

  // Helper to get description with fallback
  String get descriptionDisplay => description.isNotEmpty ? description : (notes ?? 'No description provided');

  @override
  String toString() {
    return 'ServiceLog(id: $id, assetId: $assetId, serviceType: $serviceType, performedBy: $performedBy)';
  }
}