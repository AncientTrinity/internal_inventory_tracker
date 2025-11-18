// filename: lib/services/service_log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_log.dart';
import '../utils/api_config.dart';

class ServiceLogService {
  // Get service logs for an asset
  Future<List<ServiceLog>> getServiceLogsForAsset(int assetId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/assets/$assetId/service-logs'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> logsList;
        
        if (responseData is List) {
          logsList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          logsList = responseData['data'];
        } else {
          logsList = [responseData];
        }
        
        return logsList.map((log) => ServiceLog.fromJson(log)).toList();
      } else {
        throw Exception('Failed to load service logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load service logs: $e');
    }
  }

  // Create a new service log
  Future<ServiceLog> createServiceLog(ServiceLog serviceLog, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceLog.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ServiceLog.fromJson(responseData);
      } else {
        throw Exception('Failed to create service log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create service log: $e');
    }
  }

  // Update a service log
  Future<ServiceLog> updateServiceLog(ServiceLog serviceLog, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs/${serviceLog.id}'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceLog.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ServiceLog.fromJson(responseData);
      } else {
        throw Exception('Failed to update service log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update service log: $e');
    }
  }

  // Delete a service log
  Future<void> deleteServiceLog(int logId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs/$logId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete service log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete service log: $e');
    }
  }

  // Get service log by ID
  Future<ServiceLog> getServiceLogById(int logId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs/$logId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ServiceLog.fromJson(responseData);
      } else {
        throw Exception('Failed to load service log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load service log: $e');
    }
  }
}