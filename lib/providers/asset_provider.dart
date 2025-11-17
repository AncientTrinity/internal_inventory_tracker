//filename: lib/providers/asset_provider.dart

import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import '../services/asset_service.dart';

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
    notifyListeners();

    try {
      if (filters != null) {
        _currentFilters = filters;
      }
      
      _assets = await _assetService.getAssets(
        filters: _currentFilters,
        token: token,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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
    notifyListeners();

    try {
      _selectedAsset = await _assetService.getAssetById(id, token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Create new asset
  Future<void> createAsset(Asset asset, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAsset = await _assetService.createAsset(asset, token);
      _assets.insert(0, newAsset);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update asset
  Future<void> updateAsset(Asset asset, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAsset = await _assetService.updateAsset(asset, token);
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        _assets[index] = updatedAsset;
      }
      _selectedAsset = updatedAsset;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete asset
  Future<void> deleteAsset(int id, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _assetService.deleteAsset(id, token);
      _assets.removeWhere((asset) => asset.id == id);
      if (_selectedAsset?.id == id) {
        _selectedAsset = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Assign asset to user
  Future<void> assignAsset(int assetId, int userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _assetService.assignAsset(assetId, userId, token);
      
      // Update local state
      final index = _assets.indexWhere((asset) => asset.id == assetId);
      if (index != -1) {
        _assets[index] = _assets[index].copyWith(inUseBy: userId, status: 'IN_USE');
      }
      
      if (_selectedAsset?.id == assetId) {
        _selectedAsset = _selectedAsset!.copyWith(inUseBy: userId, status: 'IN_USE');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Unassign asset
  Future<void> unassignAsset(int assetId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _assetService.unassignAsset(assetId, token);
      
      // Update local state
      final index = _assets.indexWhere((asset) => asset.id == assetId);
      if (index != -1) {
        _assets[index] = _assets[index].copyWith(inUseBy: null, status: 'IN_STORAGE');
      }
      
      if (_selectedAsset?.id == assetId) {
        _selectedAsset = _selectedAsset!.copyWith(inUseBy: null, status: 'IN_STORAGE');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected asset
  void clearSelectedAsset() {
    _selectedAsset = null;
    notifyListeners();
  }

  // Update filters
  void updateFilters(AssetFilters filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _currentFilters = AssetFilters();
    notifyListeners();
  }
}

// Extension for copying asset with updated fields
extension AssetCopyWith on Asset {
  Asset copyWith({
    int? id,
    String? internalId,
    String? assetType,
    String? manufacturer,
    String? model,
    String? modelNumber,
    String? serialNumber,
    String? status,
    int? inUseBy,
    DateTime? datePurchased,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    String? assignedToName,
    String? assignedToEmail,
  }) {
    return Asset(
      id: id ?? this.id,
      internalId: internalId ?? this.internalId,
      assetType: assetType ?? this.assetType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      inUseBy: inUseBy ?? this.inUseBy,
      datePurchased: datePurchased ?? this.datePurchased,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
    );
  }
}