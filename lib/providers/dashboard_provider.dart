//filename: lib/providers/dashboard_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/weather.dart';
import '../services/dashboard_service.dart';
import '../services/asset_service.dart';
import '../services/ticket_service.dart';
import '../services/weather_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final AssetService _assetService = AssetService();
  final TicketService _ticketService = TicketService();
  final WeatherService _weatherService = WeatherService();

  // Statistics data
  Map<String, dynamic>? _assetStats;
  Map<String, dynamic>? _ticketStats;
  WeatherData? _weatherData;
  List<Asset> _recentAssets = [];
  List<Ticket> _recentTickets = [];
  List<Asset> _assetsNeedingService = [];

  // Agent-specific data
  List<Asset> _agentAssets = [];
  List<Ticket> _agentTickets = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get assetStats => _assetStats;

  Map<String, dynamic>? get ticketStats => _ticketStats;

  List<Asset> get recentAssets => _recentAssets;

  List<Ticket> get recentTickets => _recentTickets;

  List<Asset> get assetsNeedingService => _assetsNeedingService;

  WeatherData? get weatherData => _weatherData;

  // Agent-specific getters
  List<Asset> get agentAssets => _agentAssets;

  List<Ticket> get agentTickets => _agentTickets;

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

  // Agent-specific counts
  int get agentTotalAssets => _agentAssets.length;

  int get agentTotalTickets => _agentTickets.length;

  int get agentActiveTickets => _agentTickets
      .where(
          (ticket) => ticket.isOpen || ticket.isReceived || ticket.isInProgress)
      .length;

  // Load all dashboard data
  Future<void> loadDashboardData(String token, User? currentUser) async {
    _isLoading = true;
    _error = null;

    // Delay the initial notification slightly
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });

    try {
      if (currentUser?.isAgent == true) {
        // Load agent-specific data
        await _loadAgentDashboardData(token, currentUser!);
      } else {
        // Load admin/IT/Staff dashboard data
        await _loadFullDashboardData(token);
      }

       try {
        _weatherData = await _weatherService.getDefaultWeather();
      } catch (e) {
        print('Weather load failed: $e');
        // Don't fail dashboard if weather fails
      }

      _isLoading = false;
      // Use a microtask to ensure we're not in build phase
      scheduleMicrotask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      // Use a microtask to ensure we're not in build phase
      scheduleMicrotask(() {
        notifyListeners();
      });
      rethrow;
    }
  }

  // Load agent-specific dashboard data
  Future<void> _loadAgentDashboardData(String token, User currentUser) async {
    try {
      // Load agent's assigned assets
      await _loadAgentAssets(token, currentUser.id);

      // Load tickets linked to agent's assets
      await _loadAgentTickets(token, currentUser);

      // Set agent-specific stats
      _setAgentStats();
    } catch (e) {
      rethrow;
    }
  }

  // Load full dashboard data for Admin/IT/Staff
  Future<void> _loadFullDashboardData(String token) async {
    try {
      await Future.wait([
        _loadAssetStats(token),
        _loadTicketStats(token),
        _loadRecentAssets(token),
        _loadRecentTickets(token),
        _loadAssetsNeedingService(token),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // Load agent's assigned assets
  Future<void> _loadAgentAssets(String token, int agentId) async {
    try {
      // Get all assets and filter for this agent
      final allAssets = await _assetService.getAssets(token: token);
      _agentAssets =
          allAssets.where((asset) => asset.inUseBy == agentId).toList();
    } catch (e) {
      _agentAssets = [];
      rethrow;
    }
  }

  // Load tickets linked to agent's assets
  Future<void> _loadAgentTickets(String token, User currentUser) async {
    try {
      // Get all tickets
      final allTickets = await _ticketService.getTickets(token);

      // Filter tickets:
      // 1. Tickets created by the agent
      // 2. Tickets linked to assets assigned to the agent
      final agentAssetIds = _agentAssets.map((asset) => asset.id).toList();

      _agentTickets = allTickets.where((ticket) {
        final isCreatedByAgent = ticket.createdBy == currentUser.id;
        final isLinkedToAgentAsset =
            ticket.assetId != null && agentAssetIds.contains(ticket.assetId);

        return isCreatedByAgent || isLinkedToAgentAsset;
      }).toList();
    } catch (e) {
      _agentTickets = [];
      rethrow;
    }
  }

  // Set agent-specific statistics
  void _setAgentStats() {
    // Asset stats for agent
    _assetStats = {
      'total_assets': _agentAssets.length,
      'in_use': _agentAssets.length, // All agent assets are in use by them
      'in_storage': 0,
      'in_repair': _agentAssets.where((asset) => asset.isInRepair).length,
      'needs_service': _agentAssets.where((asset) => asset.needsService).length,
      'asset_types_count': _getAgentAssetTypeCount(),
    };

    // Ticket stats for agent
    final openTickets = _agentTickets.where((t) => t.isOpen).length;
    final inProgressTickets = _agentTickets.where((t) => t.isInProgress).length;
    final resolvedTickets = _agentTickets.where((t) => t.isResolved).length;
    final criticalTickets =
        _agentTickets.where((t) => t.priority == 'critical').length;

    _ticketStats = {
      'total': _agentTickets.length,
      'open': openTickets,
      'received': _agentTickets.where((t) => t.isReceived).length,
      'in_progress': inProgressTickets,
      'resolved': resolvedTickets,
      'closed': _agentTickets.where((t) => t.isClosed).length,
      'critical': criticalTickets,
    };

    // Recent assets for agent (their assigned assets)
    _recentAssets = _agentAssets.take(5).toList();

    // Recent tickets for agent
    _recentTickets = _agentTickets.take(5).toList();

    // Assets needing service for agent
    _assetsNeedingService =
        _agentAssets.where((asset) => asset.needsService).toList();
  }

  // Helper method to count asset types for agent
  Map<String, int> _getAgentAssetTypeCount() {
    final typeCount = <String, int>{};
    for (final asset in _agentAssets) {
      typeCount.update(
        asset.assetType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return typeCount;
  }

  // Refresh dashboard data
  Future<void> refreshData(String token, User? currentUser) async {
    await loadDashboardData(token, currentUser);
  }

  // Individual data loading methods for full dashboard
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
      _assetsNeedingService =
          await _dashboardService.getAssetsNeedingService(token);
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
