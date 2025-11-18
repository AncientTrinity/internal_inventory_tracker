// filename: lib/services/service_log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_log.dart';
import '../utils/api_config.dart';

class ServiceLogService {
  
  // Enhanced response handler for your API patterns
  dynamic _handleResponse(http.Response response) {
    print('🔍 Service Log Response - Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');
    
    // Check for plain text errors
    if (response.headers['content-type']?.contains('text/plain') == true) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body);
        } catch (e) {
          return response.body;
        }
      } else {
        throw Exception(response.body);
      }
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseBody = json.decode(response.body);
        
        // Handle your API's mixed formats:
        if (responseBody is List) {
          // RAW ARRAY format (like /assets, /users)
          return responseBody;
        } else if (responseBody is Map) {
          // WRAPPED OBJECT format (like assignment responses)
          return responseBody['data'] ?? responseBody['service_log'] ?? responseBody;
        } else {
          return responseBody;
        }
      } catch (e) {
        print('❌ JSON decode error: $e');
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Get service logs for an asset - expects RAW ARRAY
  Future<List<ServiceLog>> getServiceLogsForAsset(int assetId, String token) async {
    try {
      print('📡 Fetching service logs for asset $assetId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/assets/$assetId/service-logs'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      List<dynamic> logsList;
      
      // Handle both array and object responses
      if (responseData is List) {
        logsList = responseData;
      } else if (responseData is Map && responseData.containsKey('service_logs')) {
        logsList = responseData['service_logs'];
      } else if (responseData is Map && responseData.containsKey('data')) {
        logsList = responseData['data'];
      } else {
        logsList = [responseData];
      }
      
      print('📦 Parsed ${logsList.length} service logs');
      
      // Convert each item to ServiceLog with proper type casting
      return logsList.map<ServiceLog>((log) {
        if (log is Map) {
          return ServiceLog.fromJson(Map<String, dynamic>.from(log));
        }
        throw Exception('Invalid service log data: $log');
      }).toList();
    } catch (e) {
      print('❌ Failed to load service logs: $e');
      throw Exception('Failed to load service logs: $e');
    }
  }

  // Create service log - expects WRAPPED OBJECT response
  Future<ServiceLog> createServiceLog(ServiceLog serviceLog, String token) async {
    try {
      print('📡 Creating service log for asset ${serviceLog.assetId}');
      print('📤 Request Body: ${serviceLog.toJson()}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/assets/${serviceLog.assetId}/service-logs'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceLog.toJson()),
      );

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      final responseData = _handleResponse(response);
      
      // Handle the response - your API returns the created service log directly
      if (responseData is Map) {
        // FIX: Explicitly cast to Map<String, dynamic>
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to create service log: $e');
      throw Exception('Failed to create service log: $e');
    }
  }

  // Update service log - expects WRAPPED OBJECT response  
  Future<ServiceLog> updateServiceLog(ServiceLog serviceLog, String token) async {
    try {
      print('📡 Updating service log ${serviceLog.id}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs/${serviceLog.id}'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceLog.toJson()),
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map && responseData.containsKey('service_log')) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData['service_log']));
      } else if (responseData is Map && responseData.containsKey('data')) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData['data']));
      } else if (responseData is Map) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to update service log: $e');
      throw Exception('Failed to update service log: $e');
    }
  }

  // Delete service log
  Future<void> deleteServiceLog(int logId, String token) async {
    try {
      print('📡 Deleting service log $logId');
      
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
      print('❌ Failed to delete service log: $e');
      throw Exception('Failed to delete service log: $e');
    }
  }

  // Get service log by ID - expects WRAPPED OBJECT response
  Future<ServiceLog> getServiceLogById(int logId, String token) async {
    try {
      print('📡 Fetching service log $logId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/service-logs/$logId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map && responseData.containsKey('service_log')) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData['service_log']));
      } else if (responseData is Map && responseData.containsKey('data')) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData['data']));
      } else if (responseData is Map) {
        return ServiceLog.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to load service log: $e');
      throw Exception('Failed to load service log: $e');
    }
  }
}