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

    final newAssets = await _assetService.getAssets(
      filters: _currentFilters,
      token: token,
    );

    // The API doesn't provide user details, so we rely on our local state
    // But we need to make sure the assignment status matches the API data
    for (final newAsset in newAssets) {
      final existingAssetIndex = _assets.indexWhere((a) => a.id == newAsset.id);
      if (existingAssetIndex != -1) {
        final existingAsset = _assets[existingAssetIndex];
        
        // If the API says the asset is assigned but we don't have user details locally,
        // or if the assignment status changed, update our local state
        if (newAsset.inUseBy != null && existingAsset.assignedToName == null) {
          // Asset is assigned according to API but we don't have user details
          // We can't display user details, but we should update the assignment status
          final newAssetIndex = newAssets.indexWhere((a) => a.id == newAsset.id);
          if (newAssetIndex != -1) {
            newAssets[newAssetIndex] = newAsset.copyWith(
              status: 'IN_USE',
            );
          }
        } else if (newAsset.inUseBy == null && existingAsset.assignedToName != null) {
          // Asset is unassigned according to API but we still have user details locally
          // Clear the local user details to match the API state
          final newAssetIndex = newAssets.indexWhere((a) => a.id == newAsset.id);
          if (newAssetIndex != -1) {
            newAssets[newAssetIndex] = newAsset.copyWith(
              assignedToName: null,
              assignedToEmail: null,
              status: 'IN_STORAGE',
            );
          }
        }
      }
    }

    _assets = newAssets;
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
  // Enhance all assigned assets with user details
  Future<void> _enhanceAssetWithUserDetails(Asset asset) async {
  try {
    if (asset.inUseBy != null) {
      // We need access to auth provider to get user details
      // For now, we'll use a direct API call or rely on the auth provider context
      final userDetails = await _getUserDetails(asset.inUseBy!);
      if (userDetails != null) {
        final updatedAsset = asset.copyWith(
          assignedToName: userDetails['name'],
          assignedToEmail: userDetails['email'],
        );
        
        // Update in local list
        final assetIndex = _assets.indexWhere((a) => a.id == asset.id);
        if (assetIndex != -1) {
          _assets[assetIndex] = updatedAsset;
        }
        
        if (_selectedAsset?.id == asset.id) {
          _selectedAsset = updatedAsset;
        }
        
        notifyListeners();
        print('✅ Enhanced asset ${asset.internalId} with user: ${userDetails['name']}');
      }
    }
  } catch (e) {
    print('❌ Failed to enhance asset with user details: $e');
  }
}

Future<void> _enhanceAssetsWithUserDetails() async {
  try {
    for (final asset in _assets) {
      if (asset.inUseBy != null && asset.assignedToName == null) {
        await _enhanceAssetWithUserDetails(asset);
      }
    }
  } catch (e) {
    print('❌ Failed to enhance assets with user details: $e');
  }
}
 
  // Helper to get user details by ID
  Future<Map<String, String>?> _getUserDetails(int userId) async {
  try {
    final token = await SecureStorageService.getToken();
    if (token == null) return null;

    // You need to implement this based on your users API
    // This is a placeholder - adjust based on your actual users endpoint
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      return {
        'name': userData['full_name'] ?? userData['username'] ?? 'Unknown User',
        'email': userData['email'] ?? '',
      };
    }
  } catch (e) {
    print('❌ Failed to get user details for ID $userId: $e');
  }
  return null;
}

  // Refresh assets
  Future<void> refreshAssets(String token) async {
    await loadAssets(token);
  }

Future<void> loadAssetById(int id, String token) async {
  _isLoading = true;
  _error = null;
  scheduleMicrotask(() {
    notifyListeners();
  });

  try {
    _selectedAsset = await _assetService.getAssetById(id, token);
    
    // If asset is assigned to a user, fetch user details
    if (_selectedAsset?.inUseBy != null) {
      await _enhanceAssetWithUserDetails(_selectedAsset!);
    }
    
    print('🔍 Loaded Asset Details:');
    print('🔍 Asset ID: ${_selectedAsset?.id}');
    print('🔍 Internal ID: ${_selectedAsset?.internalId}');
    print('🔍 Assigned To: ${_selectedAsset?.inUseBy}');
    print('🔍 Assigned Name: ${_selectedAsset?.assignedToName}');
    print('🔍 Assigned Email: ${_selectedAsset?.assignedToEmail}');
    
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
// In lib/providers/asset_provider.dart - Complete assignment methods

// ========== ASSIGNMENT METHODS ==========

// Individual asset assignment
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

// Bulk asset assignment

Future<void> bulkAssignAssets(List<int> assetIds, int userId, String userName, String userEmail) async {
  try {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final url = '${ApiConfig.apiBaseUrl}/assets/bulk-assign';
    
    print('🔍 Bulk Assign Assets API Call:');
    print('🔍 Asset IDs: $assetIds');
    print('🔍 User ID: $userId');
    print('🔍 User Name: $userName');
    print('🔍 User Email: $userEmail');

    // FIX: Use "asset_ids" instead of "assetIds"
    final requestBody = {
      'asset_ids': assetIds, // Changed from 'assetIds' to 'asset_ids'
      'user_id': userId,
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
      final responseData = json.decode(response.body);
      final successIds = List<int>.from(responseData['success'] ?? []);
      final failedIds = List<int>.from(responseData['failed'] ?? []);
      
      print('✅ Bulk assignment successful for assets: $successIds');
      if (failedIds.isNotEmpty) {
        print('❌ Bulk assignment failed for assets: $failedIds');
      }

      // Only update local state for successfully assigned assets
      for (final assetId in successIds) {
        _updateLocalAssetWithUserDetails(assetId, userId, userName, userEmail);
      }
      
      print('✅ ${successIds.length} assets bulk assigned to $userName');
      
      // If there were failures, throw an error
      if (failedIds.isNotEmpty) {
        throw Exception('Failed to assign assets: $failedIds');
      }
    } else {
      throw Exception('Failed to bulk assign assets: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Bulk assignment failed: $e');
    throw Exception('Bulk assignment failed: $e');
  }
}
// Unassign individual asset
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
      // Clear user details from local asset
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