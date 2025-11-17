import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/asset.dart';
import '../utils/api_config.dart';

class AssetService {
  final String baseUrl = ApiConfig.apiBaseUrl;

  // Get all assets with optional filters
  Future<List<Asset>> getAssets({AssetFilters? filters, String? token}) async {
    final url = Uri.parse('$baseUrl/assets').replace(
      queryParameters: filters?.toQueryParams(),
    );

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Asset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assets: ${response.statusCode}');
    }
  }

  // Get asset by ID
  Future<Asset> getAssetById(int id, String token) async {
    final url = Uri.parse('$baseUrl/assets/$id');

    final response = await http.get(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return Asset.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load asset: ${response.statusCode}');
    }
  }

  // Create new asset
  Future<Asset> createAsset(Asset asset, String token) async {
    final url = Uri.parse('$baseUrl/assets');

    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode(asset.toJson()),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      return Asset.fromJson(jsonResponse);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to create asset: ${response.statusCode}');
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

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return Asset.fromJson(jsonResponse);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update asset: ${response.statusCode}');
    }
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
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete asset: ${response.statusCode}');
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

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> assetsJson = jsonResponse['assets'] ?? [];
      return assetsJson.map((json) => Asset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search assets: ${response.statusCode}');
    }
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

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to assign asset: ${response.statusCode}');
    }
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

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to unassign asset: ${response.statusCode}');
    }
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

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Asset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load available assets: ${response.statusCode}');
    }
  }
}