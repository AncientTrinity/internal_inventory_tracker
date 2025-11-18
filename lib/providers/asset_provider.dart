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

   // for export functionality
   List<Asset> getAssetsForExport(String scope) {
  switch (scope) {
    case 'all':
      return _assets;
    case 'filtered':
      return filteredAssets;
    case 'selected':
      // You would need to track selected assets for this
      return filteredAssets; // Placeholder
    default:
      return filteredAssets;
  }
}


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
// Update the assignAsset method to use the nullable version
// In lib/providers/asset_provider.dart - Replace from the original assignAsset method

// ========== ASSIGNMENT METHODS ==========

// Assign asset to user with user details
  Future<void> assignAsset(int assetId, int userId, String userName, String userEmail) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '${ApiConfig.apiBaseUrl}/assets/$assetId/assign';

      print('🔍 Assign Asset API Call:');
      print('🔍 Asset ID: $assetId');
      print('🔍 User ID: $userId');
      print('🔍 User Name: $userName');
      print('🔍 User Email: $userEmail');

      final requestBody = {
        'user_id': userId,
      };

      final body = json.encode(requestBody);

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
        // Update local state with user details
        _updateLocalAssetWithUserDetails(assetId, userId, userName, userEmail);
        print('✅ Asset assigned successfully with user details!');
      } else {
        throw Exception('Failed to assign asset: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Assignment failed: $e');
      throw Exception('Assignment failed: $e');
    }
  }

// Unassign asset
  Future<void> unassignAsset(int assetId) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '${ApiConfig.apiBaseUrl}/assets/$assetId/unassign';

      print('🔍 Unassign Asset API Call:');
      print('🔍 Asset ID: $assetId');

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
        // Clear user details
        _updateLocalAssetWithUserDetails(assetId, null, null, null);
        print('✅ Asset unassigned successfully!');
      } else {
        throw Exception('Failed to unassign asset: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Unassignment failed: $e');
      throw Exception('Unassignment failed: $e');
    }
  }

// Bulk assign assets to user
  Future<void> bulkAssignAssets(List<int> assetIds, int userId, String userName, String userEmail) async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '${ApiConfig.apiBaseUrl}/assets/bulk-assign';

      final requestBody = {
        'assetIds': assetIds,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('🔍 Bulk Assign Response Status: ${response.statusCode}');
      print('🔍 Bulk Assign Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Update all assets with user details
        for (final assetId in assetIds) {
          _updateLocalAssetWithUserDetails(assetId, userId, userName, userEmail);
        }
        print('✅ ${assetIds.length} assets bulk assigned to $userName');
      } else {
        throw Exception('Failed to bulk assign assets: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Bulk assignment failed: $e');
      throw Exception('Bulk assignment failed: $e');
    }
  }

// Helper method to update local asset state with user assignment details
  void _updateLocalAssetWithUserDetails(int assetId, int? userId, String? userName, String? userEmail) {
    final assetIndex = _assets.indexWhere((asset) => asset.id == assetId);
    if (assetIndex != -1) {
      final asset = _assets[assetIndex];
      final updatedAsset = asset.copyWith(
        inUseBy: userId,
        assignedToName: userName,
        assignedToEmail: userEmail,
        status: userId != null ? 'IN_USE' : 'IN_STORAGE',
      );

      _assets[assetIndex] = updatedAsset;

      if (_selectedAsset?.id == assetId) {
        _selectedAsset = updatedAsset;
      }

      notifyListeners();

      if (userId != null) {
        print('✅ Local asset updated with user: $userName ($userEmail)');
      } else {
        print('✅ Local asset updated - unassigned');
      }
    }
  }

// ========== END ASSIGNMENT METHODS ==========

// The rest of your asset provider methods (clearError, clearSelectedAsset, etc.) continue below...

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