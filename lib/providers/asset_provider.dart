// filename: lib/providers/asset_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/api_config.dart';

class AssetProvider with ChangeNotifier {
  final AssetService _assetService = AssetService();

  List<Asset> _assets = [];
  Asset? _selectedAsset;
  bool _isLoading = false;
  String? _error;
  AssetFilters _currentFilters = AssetFilters();

  // Getters
  List<Asset> get assets => _assets;
  Asset? get selectedAsset => _selectedAsset;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AssetFilters get currentFilters => _currentFilters;

  // Filtered assets
  List<Asset> get filteredAssets {
    var filtered = _assets;

    if (_currentFilters.searchQuery != null && _currentFilters.searchQuery!.isNotEmpty) {
      final query = _currentFilters.searchQuery!.toLowerCase();
      filtered = filtered.where((asset) =>
      asset.internalId.toLowerCase().contains(query) ||
          asset.manufacturer.toLowerCase().contains(query) ||
          asset.model.toLowerCase().contains(query) ||
          asset.serialNumber.toLowerCase().contains(query) ||
          asset.assetType.toLowerCase().contains(query)
      ).toList();
    }

    if (_currentFilters.assetType != null && _currentFilters.assetType!.isNotEmpty) {
      filtered = filtered.where((asset) => asset.assetType == _currentFilters.assetType).toList();
    }

    if (_currentFilters.status != null && _currentFilters.status!.isNotEmpty) {
      filtered = filtered.where((asset) => asset.status == _currentFilters.status).toList();
    }

    if (_currentFilters.manufacturer != null && _currentFilters.manufacturer!.isNotEmpty) {
      filtered = filtered.where((asset) => asset.manufacturer == _currentFilters.manufacturer).toList();
    }

    if (_currentFilters.inUseBy != null) {
      filtered = filtered.where((asset) => asset.inUseBy == _currentFilters.inUseBy).toList();
    }

    if (_currentFilters.needsService == true) {
      filtered = filtered.where((asset) => asset.needsService).toList();
    }

    if (_currentFilters.assignmentStatus != null) {
      if (_currentFilters.assignmentStatus == 'assigned') {
        filtered = filtered.where((asset) => asset.isAssigned).toList();
      } else if (_currentFilters.assignmentStatus == 'unassigned') {
        filtered = filtered.where((asset) => !asset.isAssigned).toList();
      }
    }

    return filtered;
  }

  // Statistics
  int get totalAssets => _assets.length;
  int get assetsInUse => _assets.where((asset) => asset.isInUse).length;
  int get assetsInStorage => _assets.where((asset) => asset.isInStorage).length;
  int get assetsInRepair => _assets.where((asset) => asset.isInRepair).length;
  int get assetsNeedingService => _assets.where((asset) => asset.needsService).length;

  // Load all assets
  Future<void> loadAssets(String token, {AssetFilters? filters}) async {
    _isLoading = true;
    _error = null;

    scheduleMicrotask(() {
      notifyListeners();
    });

    try {
      if (filters != null) {
        _currentFilters = filters;
      }

      _assets = await _assetService.getAssets(
        filters: _currentFilters,
        token: token,
      );

      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Refresh assets
  Future<void> refreshAssets(String token) async {
    await loadAssets(token);
  }

  // Load asset by ID
  Future<void> loadAssetById(int id, String token) async {
    _isLoading = true;
    _error = null;
    scheduleMicrotask(() {
      notifyListeners();
    });

    try {
      _selectedAsset = await _assetService.getAssetById(id, token);
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Create new asset
  Future<void> createAsset(Asset asset, String token) async {
    _isLoading = true;
    _error = null;
    scheduleMicrotask(() {
      notifyListeners();
    });

    try {
      final newAsset = await _assetService.createAsset(asset, token);
      _assets.insert(0, newAsset);
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Update asset
  Future<void> updateAsset(Asset asset, String token) async {
    _isLoading = true;
    _error = null;
    scheduleMicrotask(() {
      notifyListeners();
    });

    try {
      final updatedAsset = await _assetService.updateAsset(asset, token);
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        _assets[index] = updatedAsset;
      }
      _selectedAsset = updatedAsset;
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Delete asset
  Future<void> deleteAsset(int id, String token) async {
    _isLoading = true;
    _error = null;
    scheduleMicrotask(() {
      notifyListeners();
    });

    try {
      await _assetService.deleteAsset(id, token);
      _assets.removeWhere((asset) => asset.id == id);
      if (_selectedAsset?.id == id) {
        _selectedAsset = null;
      }
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Replace the assignAsset and unassignAsset methods in lib/providers/asset_provider.dart

// Assign asset to user - CORRECTED VERSION
// Update the assignAsset method in lib/providers/asset_provider.dart

Future<void> assignAsset(int assetId, int userId) async {
  try {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = '${ApiConfig.apiBaseUrl}/assets/$assetId/assign';
    
    print('🔍 Assign Asset API Call:');
    print('🔍 Asset ID: $assetId');
    print('🔍 User ID: $userId');
    print('🔍 URL: $url');

    // Use the correct parameter name: user_id (with underscore)
    final requestBody = {
      'user_id': userId, // This is what the API expects
    };

    final body = json.encode(requestBody);
    
    print('🔍 Request Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('🔍 Response Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Asset assigned successfully!');
      
      // Parse the response to get updated asset data
      final responseData = json.decode(response.body);
      final updatedAsset = responseData['asset'];
      print('✅ Updated asset: ${updatedAsset['internal_id']} assigned to user ${updatedAsset['in_use_by']}');
    } else {
      throw Exception('Failed to assign asset: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Assignment failed: $e');
    throw Exception('Assignment failed: $e');
  }
}
// Unassign asset - CORRECTED VERSION
// Update the unassignAsset method in lib/providers/asset_provider.dart

Future<void> unassignAsset(int assetId) async {
  try {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = '${ApiConfig.apiBaseUrl}/assets/$assetId/unassign';
    
    print('🔍 Unassign Asset API Call:');
    print('🔍 Asset ID: $assetId');
    print('🔍 URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🔍 Response Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Asset unassigned successfully!');
      
      // Parse the response to get updated asset data
      final responseData = json.decode(response.body);
      final updatedAsset = responseData['asset'];
      print('✅ Updated asset: ${updatedAsset['internal_id']} is now unassigned');
    } else {
      throw Exception('Failed to unassign asset: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Unassignment failed: $e');
    throw Exception('Unassignment failed: $e');
  }
}


Future<void> bulkAssignAssets(List<int> assetIds, int userId) async {
  try {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = '${ApiConfig.apiBaseUrl}/assets/bulk-assign';
    
    print('🔍 Bulk Assign Assets API Call:');
    print('🔍 Asset IDs: $assetIds');
    print('🔍 User ID: $userId');
    print('🔍 URL: $url');

    // Use the correct parameter name: user_id (with underscore)
    final requestBody = {
      'assetIds': assetIds,
      'user_id': userId, // Use user_id like the individual assignment
    };

    final body = json.encode(requestBody);
    
    print('🔍 Request Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('🔍 Response Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Assets bulk assigned successfully!');
      
      // Refresh the assets list to show updated assignments
      await loadAssets(token);
    } else {
      throw Exception('Failed to bulk assign assets: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Bulk assignment failed: $e');
    throw Exception('Bulk assignment failed: $e');
  }
}
  // Clear error
  void clearError() {
    _error = null;
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // Clear selected asset
  void clearSelectedAsset() {
    _selectedAsset = null;
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // Update filters
  void updateFilters(AssetFilters filters) {
    _currentFilters = filters;
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // Clear filters
  void clearFilters() {
    _currentFilters = AssetFilters();
    scheduleMicrotask(() {
      notifyListeners();
    });
  }
}