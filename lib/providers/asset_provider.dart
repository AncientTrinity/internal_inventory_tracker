import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/asset_service_log.dart';
import '../models/asset_stats.dart';
import '../services/api_service.dart';

class AssetProvider with ChangeNotifier {
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  Asset? _selectedAsset;
  List<AssetServiceLog> _serviceLogs = [];
  AssetStats? _stats;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterType = '';
  String _filterStatus = '';

  List<Asset> get assets => _filteredAssets;
  List<Asset> get allAssets => _assets;
  Asset? get selectedAsset => _selectedAsset;
  List<AssetServiceLog> get serviceLogs => _serviceLogs;
  AssetStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssets() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/assets');
      _assets = (response as List).map((json) => Asset.fromJson(json)).toList();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load assets: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAssetStats() async {
    try {
      final response = await ApiService.get('/assets/stats');
      _stats = AssetStats.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load asset statistics: $e';
    }
  }

  Future<Asset?> getAssetById(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/assets/$id');
      _selectedAsset = Asset.fromJson(response);
      notifyListeners();
      return _selectedAsset;
    } catch (e) {
      _error = 'Failed to load asset: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadServiceLogs(int assetId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/assets/$assetId/service-logs');
      _serviceLogs = (response as List).map((json) => AssetServiceLog.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load service logs: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAsset(Asset asset) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.post('/assets', asset.toJson());
      final newAsset = Asset.fromJson(response);
      _assets.insert(0, newAsset);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create asset: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAsset(Asset asset) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.put('/assets/${asset.id}', asset.toJson());
      final updatedAsset = Asset.fromJson(response);
      
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        _assets[index] = updatedAsset;
      }
      
      if (_selectedAsset?.id == asset.id) {
        _selectedAsset = updatedAsset;
      }
      
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update asset: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignAsset(int assetId, int userId) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/assets/$assetId/assign', {'user_id': userId});
      await loadAssets(); // Reload to get updated data
      return true;
    } catch (e) {
      _error = 'Failed to assign asset: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unassignAsset(int assetId) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/assets/$assetId/unassign', {});
      await loadAssets(); // Reload to get updated data
      return true;
    } catch (e) {
      _error = 'Failed to unassign asset: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addServiceLog(AssetServiceLog log) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/assets/${log.assetId}/service-logs', log.toJson());
      await loadServiceLogs(log.assetId); // Reload service logs
      await loadAssets(); // Reload assets to update service dates
      return true;
    } catch (e) {
      _error = 'Failed to add service log: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search and filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = '';
    _filterStatus = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredAssets = _assets.where((asset) {
      final matchesSearch = _searchQuery.isEmpty ||
          asset.internalId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.model?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          asset.manufacturer?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      final matchesType = _filterType.isEmpty || asset.assetType == _filterType;
      final matchesStatus = _filterStatus.isEmpty || asset.status == _filterStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  List<Asset> getAvailableAssets(String? type) {
    return _assets.where((asset) {
      final isAvailable = asset.status == 'IN_STORAGE' && asset.inUseBy == null;
      final matchesType = type == null || asset.assetType == type;
      return isAvailable && matchesType;
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedAsset = null;
    _serviceLogs = [];
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}