// filename: lib/services/reports_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../utils/api_config.dart';

class ReportsService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  // Get comprehensive report data with better error handling
  Future<ReportData> getReportData(ReportFilter filter, String token) async {
    final url = Uri.parse('$baseUrl/reports/analytics');
    
    print('🔍 ReportsService: Sending request to $url');
    
    // Try different date formats
    Map<String, dynamic> requestBody;
    
    // Try format 1: ISO without milliseconds
    requestBody = {
      'start_date': _formatDateISO(filter.startDate),
      'end_date': _formatDateISO(filter.endDate),
      'asset_type': filter.assetType,
      'ticket_type': filter.ticketType,
      'user_id': filter.userId,
      'priority': filter.priority,
    };
    
    print('🔍 ReportsService: Request body: ${json.encode(requestBody)}');
    print('🔍 ReportsService: Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.post(
        url,
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('🔍 ReportsService: Response status: ${response.statusCode}');
      print('🔍 ReportsService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 ReportsService: Successfully parsed report data');
        return ReportData.fromJson(data);
      } else if (response.statusCode == 400) {
        // Try alternative date format if 400 error
        print('🔍 ReportsService: Trying alternative date format...');
        return await _tryAlternativeFormat(filter, token);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied - you do not have permission to view reports');
      } else if (response.statusCode == 404) {
        throw Exception('Reports endpoint not found - check server configuration');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error - please try again later');
      } else {
        throw Exception('Failed to load report data: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('🔍 ReportsService: ClientException: $e');
      throw Exception('Network error: Please check your internet connection');
    } on FormatException catch (e) {
      print('🔍 ReportsService: FormatException: $e');
      throw Exception('Invalid response format from server');
    } on TimeoutException catch (e) {
      print('🔍 ReportsService: TimeoutException: $e');
      throw Exception('Request timeout - server is taking too long to respond');
    } catch (e) {
      print('🔍 ReportsService: Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // Try alternative date format
  Future<ReportData> _tryAlternativeFormat(ReportFilter filter, String token) async {
    final url = Uri.parse('$baseUrl/reports/analytics');
    
    // Try date-only format
    final requestBody = {
      'start_date': _formatDateOnly(filter.startDate),
      'end_date': _formatDateOnly(filter.endDate),
      'asset_type': filter.assetType,
      'ticket_type': filter.ticketType,
      'user_id': filter.userId,
      'priority': filter.priority,
    };
    
    print('🔍 ReportsService: Trying alternative format: ${json.encode(requestBody)}');

    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ReportData.fromJson(data);
    } else {
      throw Exception('Failed to load report data with all date formats: ${response.statusCode} - ${response.body}');
    }
  }

  // Format: YYYY-MM-DDTHH:MM:SSZ
  String _formatDateISO(DateTime date) {
    final utcDate = date.toUtc();
    final year = utcDate.year.toString().padLeft(4, '0');
    final month = utcDate.month.toString().padLeft(2, '0');
    final day = utcDate.day.toString().padLeft(2, '0');
    final hour = utcDate.hour.toString().padLeft(2, '0');
    final minute = utcDate.minute.toString().padLeft(2, '0');
    final second = utcDate.second.toString().padLeft(2, '0');
    
    return '${year}-${month}-${day}T${hour}:${minute}:${second}Z';
  }

  // Format: YYYY-MM-DD
  String _formatDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    
    return '${year}-${month}-${day}';
  }

  // Export report as CSV
  Future<String> exportReportCSV(ReportFilter filter, String token) async {
    final url = Uri.parse('$baseUrl/reports/export/csv');

    print('🔍 ReportsService: Exporting CSV to $url');

    try {
      final response = await http.post(
        url,
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'start_date': _formatDateISO(filter.startDate),
          'end_date': _formatDateISO(filter.endDate),
          'asset_type': filter.assetType,
          'ticket_type': filter.ticketType,
          'user_id': filter.userId,
          'priority': filter.priority,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to export report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  // Get available report types
  Future<List<String>> getReportTypes(String token) async {
    final url = Uri.parse('$baseUrl/reports/types');

    try {
      final response = await http.get(
        url,
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> types = data['report_types'] ?? [];
        return types.cast<String>();
      } else {
        throw Exception('Failed to load report types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load report types: $e');
    }
  }
}