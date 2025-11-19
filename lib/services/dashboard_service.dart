//filename: lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/asset.dart';
import '../models/ticket.dart';
import '../utils/api_config.dart';

class DashboardService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  // Get asset statistics
  Future<Map<String, dynamic>> getAssetStats(String token) async {
    final url = Uri.parse('$baseUrl/assets/stats');

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load asset stats: ${response.statusCode}');
    }
  }

  // Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats(String token) async {
    final url = Uri.parse('$baseUrl/tickets/stats');

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load ticket stats: ${response.statusCode}');
    }
  }

  // Get recent assets
  Future<List<Asset>> getRecentAssets(String token) async {
  final url = Uri.parse('$baseUrl/assets?limit=5');

  final response = await http.get(
    url,
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final dynamic responseBody = json.decode(response.body);
    
    List<dynamic> assetsList;
    if (responseBody is List) {
      assetsList = responseBody; // Raw array
    } else if (responseBody is Map) {
      assetsList = responseBody['data'] ?? responseBody['assets'] ?? [];
    } else {
      assetsList = [];
    }
    
    return assetsList.map((json) => Asset.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load recent assets: ${response.statusCode}');
  }
}


  // Get recent tickets
  Future<List<Ticket>> getRecentTickets(String token) async {
  final url = Uri.parse('$baseUrl/tickets?limit=5');

  final response = await http.get(
    url,
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final dynamic responseBody = json.decode(response.body);
    
    List<dynamic> ticketsList;
    if (responseBody is List) {
      ticketsList = responseBody; // Raw array
    } else if (responseBody is Map) {
      ticketsList = responseBody['data'] ?? responseBody['tickets'] ?? [];
    } else {
      ticketsList = [];
    }
    
    return ticketsList.map((json) => Ticket.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load recent tickets: ${response.statusCode}');
  }
}

  // Get assets needing service
  Future<List<Asset>> getAssetsNeedingService(String token) async {
  final url = Uri.parse('$baseUrl/assets/search?needs_service=true');

  final response = await http.get(
    url,
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final dynamic responseBody = json.decode(response.body);
    
    List<dynamic> assetsList;
    if (responseBody is List) {
      assetsList = responseBody; // Raw array
    } else if (responseBody is Map) {
      assetsList = responseBody['assets'] ?? responseBody['data'] ?? [];
    } else {
      assetsList = [];
    }
    
    return assetsList.map((json) => Asset.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load assets needing service: ${response.statusCode}');
  }
}


}