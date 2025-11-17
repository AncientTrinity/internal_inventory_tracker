import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import '../models/ticket.dart';
import '../services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  // Statistics data
  Map<String, dynamic>? _assetStats;
  Map<String, dynamic>? _ticketStats;
  List<Asset> _recentAssets = [];
  List<Ticket> _recentTickets = [];
  List<Asset> _assetsNeedingService = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get assetStats => _assetStats;
  Map<String, dynamic>? get ticketStats => _ticketStats;
  List<Asset> get recentAssets => _recentAssets;
  List<Ticket> get recentTickets => _recentTickets;
  List<Asset> get assetsNeedingService => _assetsNeedingService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total assets count
  int get totalAssets => _assetStats?['total_assets'] ?? 0;
  int get assetsInUse => _assetStats?['in_use'] ?? 0;
  int get assetsInStorage => _assetStats?['in_storage'] ?? 0;
  int get assetsInRepair => _assetStats?['in_repair'] ?? 0;
  int get assetsNeedingServiceCount => _assetStats?['needs_service'] ?? 0;

  // Get ticket counts
  int get totalTickets => _ticketStats?['total'] ?? 0;
  int get openTickets => _ticketStats?['open'] ?? 0;
  int get inProgressTickets => _ticketStats?['in_progress'] ?? 0;
  int get resolvedTickets => _ticketStats?['resolved'] ?? 0;
  int get criticalTickets => _ticketStats?['critical'] ?? 0;

  // Load all dashboard data
  Future<void> loadDashboardData(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load data in parallel for better performance
      await Future.wait([
        _loadAssetStats(token),
        _loadTicketStats(token),
        _loadRecentAssets(token),
        _loadRecentTickets(token),
        _loadAssetsNeedingService(token),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Refresh dashboard data
  Future<void> refreshData(String token) async {
    await loadDashboardData(token);
  }

  // Individual data loading methods
  Future<void> _loadAssetStats(String token) async {
    try {
      _assetStats = await _dashboardService.getAssetStats(token);
    } catch (e) {
      // If asset stats endpoint fails, provide default values
      _assetStats = {
        'total_assets': 0,
        'in_use': 0,
        'in_storage': 0,
        'in_repair': 0,
        'needs_service': 0,
        'asset_types_count': 0,
      };
    }
  }

  Future<void> _loadTicketStats(String token) async {
    try {
      _ticketStats = await _dashboardService.getTicketStats(token);
    } catch (e) {
      // If ticket stats endpoint fails, provide default values
      _ticketStats = {
        'total': 0,
        'open': 0,
        'received': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
        'critical': 0,
      };
    }
  }

  Future<void> _loadRecentAssets(String token) async {
    try {
      _recentAssets = await _dashboardService.getRecentAssets(token);
    } catch (e) {
      _recentAssets = [];
    }
  }

  Future<void> _loadRecentTickets(String token) async {
    try {
      _recentTickets = await _dashboardService.getRecentTickets(token);
    } catch (e) {
      _recentTickets = [];
    }
  }

  Future<void> _loadAssetsNeedingService(String token) async {
    try {
      _assetsNeedingService = await _dashboardService.getAssetsNeedingService(token);
    } catch (e) {
      _assetsNeedingService = [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}