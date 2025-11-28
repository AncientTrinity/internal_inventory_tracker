// filename: lib/services/asset_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/asset.dart';
import '../utils/api_config.dart';

class AssetService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  // Helper method to handle API responses
// Also update the _handleResponse method to be more robust
  dynamic _handleResponse(http.Response response) {
    print('🔍 Handling Response - Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseBody = json.decode(response.body);
        print('🔍 Successfully parsed JSON response');

        // Handle different response formats
        if (responseBody is List) {
          return responseBody;
        } else if (responseBody is Map) {
          return responseBody['data'] ?? responseBody['asset'] ?? responseBody;
        } else {
          return responseBody;
        }
      } catch (e) {
        print('❌ JSON decode error: $e');
        print('❌ Response body that failed to decode: ${response.body}');
        throw Exception('Invalid JSON response from server: ${response.body}');
      }
    } else {
      // Try to parse error message
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? errorBody['message'] ?? 'API Error: ${response.statusCode}');
      } catch (e) {
        // If can't parse error as JSON, use the raw response
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }

  // Get all assets with optional filters
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

    return _handleResponse(response);
  }

  // Get available filter options
  Future<Map<String, dynamic>> getFilterOptions(String token) async {
    final url = Uri.parse('$baseUrl/assets/types');


    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }


// Improved getAssets method with better error handling and debug logs
Future<List<Asset>> getAssets({AssetFilters? filters, String? token}) async {
  try {
    final url = Uri.parse('$baseUrl/assets').replace(
      queryParameters: filters?.toQueryParams(),
    );

    print('🔍 API Call: $url');

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      print('📦 Response Type: ${responseBody.runtimeType}'); // Debug the type
      
      List<dynamic> assetsList;
      
      // Handle BOTH array and object responses
      if (responseBody is List) {
        // Backend returns raw array: [{...}, {...}]
        print('✅ Backend returns raw array');
        assetsList = responseBody;
      } else if (responseBody is Map) {
        // Backend returns wrapped object: {"data": [...]}
        print('✅ Backend returns wrapped object');
        assetsList = responseBody['data'] ?? responseBody['assets'] ?? [];
      } else {
        throw Exception('Invalid response format: ${responseBody.runtimeType}');
      }
      
      final assets = assetsList.map((json) => Asset.fromJson(json)).toList();
      print('✅ Loaded ${assets.length} assets');
      return assets;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to load assets: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error loading assets: $e');
    rethrow;
  }
}

  // Get asset by ID
Future<Asset> getAssetById(int id, String token) async {
  final url = Uri.parse('${ApiConfig.apiBaseUrl}/assets/$id');

  final response = await http.get(
    url,
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  final responseData = _handleResponse(response);
  
  print('🔍 Asset Service - Raw API Response:');
  print('🔍 $responseData');
  
  return Asset.fromJson(responseData);
}

  // Create new asset
 // In lib/services/asset_service.dart - Update the createAsset method

Future<Asset> createAsset(Asset asset, String token) async {
  try {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}/assets');
    
    print('🔍 Create Asset API Call:');
    print('🔍 URL: $url');
    print('🔍 Request Body: ${asset.toJson()}');

    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode(asset.toJson()),
    );

    print('🔍 Create Asset Response:');
    print('🔍 Status Code: ${response.statusCode}');
    print('🔍 Response Headers: ${response.headers}');
    print('🔍 Raw Response Body: ${response.body}');

    // Check if response is valid JSON before parsing
    if (response.body.trim().isEmpty) {
      throw Exception('Empty response from server');
    }

    try {
      final responseData = _handleResponse(response);
      print('🔍 Parsed Response Data: $responseData');
      return Asset.fromJson(responseData);
    } catch (jsonError) {
      print('❌ JSON Parsing Error: $jsonError');
      print('❌ Raw response that failed to parse: ${response.body}');
      throw Exception('Failed to parse server response: $jsonError');
    }

  } catch (e) {
    print('❌ Create Asset Failed: $e');
    rethrow;
  }
}

  // Update asset
  Future<Asset> updateAsset(Asset asset, String token) async {
    final url = Uri.parse('$baseUrl/assets/${asset.id}');

    final response = await http.put(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode(asset.toJson()),
    );

    final responseData = _handleResponse(response);
    return Asset.fromJson(responseData);
  }

  // Delete asset
  Future<void> deleteAsset(int id, String token) async {
    final url = Uri.parse('$baseUrl/assets/$id');

    final response = await http.delete(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to delete asset: ${response.statusCode}');
    }
  }

  // Search assets
  Future<List<Asset>> searchAssets(String query, String token) async {
    final url = Uri.parse('$baseUrl/assets/search').replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = _handleResponse(response);
    final List<dynamic> assetsList = responseData is List ? responseData : responseData['assets'] ?? [];
    return assetsList.map((json) => Asset.fromJson(json)).toList();
  }

  // Assign asset to user
  Future<void> assignAsset(int assetId, int userId, String token) async {
    final url = Uri.parse('$baseUrl/assets/$assetId/assign');

    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'user_id': userId}),
    );

    _handleResponse(response); // Will throw if error
  }

  // Unassign asset
  Future<void> unassignAsset(int assetId, String token) async {
    final url = Uri.parse('$baseUrl/assets/$assetId/unassign');

    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    _handleResponse(response); // Will throw if error
  }

  // Get available assets (not assigned to anyone)
  Future<List<Asset>> getAvailableAssets(String token, {String? assetType}) async {
    final url = Uri.parse('$baseUrl/assets/available').replace(
      queryParameters: assetType != null ? {'type': assetType} : null,
    );

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = _handleResponse(response);
    final List<dynamic> assetsList = responseData is List ? responseData : responseData['assets'] ?? [];
    return assetsList.map((json) => Asset.fromJson(json)).toList();
  }
}


