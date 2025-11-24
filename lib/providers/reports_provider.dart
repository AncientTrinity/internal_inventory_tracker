// filename: lib/providers/reports_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/reports_service.dart';

class ReportsProvider with ChangeNotifier {
  final ReportsService _reportsService = ReportsService();

  ReportData? _reportData;
  ReportFilter _currentFilter = ReportFilter(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );
  bool _isLoading = false;
  String? _error;
  List<String> _reportTypes = [];

  // Getters
  ReportData? get reportData => _reportData;
  ReportFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get reportTypes => _reportTypes;

  // Load report data with enhanced error handling
  Future<void> loadReportData(String token) async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    _isLoading = true;
    _error = null;
    
    print('🔍 ReportsProvider: Starting to load report data...');

    try {
      _reportData = await _reportsService.getReportData(_currentFilter, token);
      _error = null;
      print('🔍 ReportsProvider: Successfully loaded report data');
    } catch (e) {
      _error = e.toString();
      _reportData = null;
      print('🔍 ReportsProvider: Error loading report data: $e');
    } finally {
      _isLoading = false;
      // Use post-frame callback to safely notify listeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Update filter
  void updateFilter(ReportFilter newFilter) {
    _currentFilter = newFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear all filters
  void clearFilters() {
    _currentFilter = ReportFilter(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Export report
  Future<String> exportReport(String token) async {
    try {
      return await _reportsService.exportReportCSV(_currentFilter, token);
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  // Load report types
  Future<void> loadReportTypes(String token) async {
    try {
      _reportTypes = await _reportsService.getReportTypes(token);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _reportTypes = [];
      print('🔍 ReportsProvider: Error loading report types: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set error
  void setError(String error) {
    _error = error;
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

 Map<String, dynamic> get computedStats {
  if (_reportData == null) return {};

  final ticketStats = _reportData!.ticketStats;
  final assetStats = _reportData!.assetStats;

  // Debug output
  print('🔍 ASSET STATS DEBUG:');
  print('🔍   - total_assets: ${assetStats['total_assets']}');
  print('🔍   - in_use: ${assetStats['in_use']}');
  print('🔍   - in_storage: ${assetStats['in_storage']}');
  print('🔍   - in_repair: ${assetStats['in_repair']}');
  print('🔍   - retired: ${assetStats['retired']}');
  print('🔍   - needs_service: ${assetStats['needs_service']}');
  
  final utilizationRate = _calculateUtilizationRate(assetStats);
  print('🔍   - calculated utilization: $utilizationRate%');

  return {
    'ticket_resolution_rate': _calculateResolutionRate(ticketStats),
    'asset_utilization_rate': utilizationRate,
    'avg_ticket_resolution_time': _calculateAvgResolutionTime(ticketStats),
    'critical_ticket_percentage': _calculateCriticalTicketPercentage(ticketStats),
  };
}
  // Get chart-specific data
  List<Map<String, dynamic>> getTicketStatusData() {
    if (_reportData == null) return [];
    
    final stats = _reportData!.ticketStats;
    return [
      {'status': 'Open', 'count': stats['open'] ?? 0, 'color': Colors.orange},
      {'status': 'In Progress', 'count': stats['in_progress'] ?? 0, 'color': Colors.blue},
      {'status': 'Resolved', 'count': stats['resolved'] ?? 0, 'color': Colors.green},
      {'status': 'Closed', 'count': stats['closed'] ?? 0, 'color': Colors.grey},
    ];
  }

  List<Map<String, dynamic>> getAssetUtilizationData() {
    if (_reportData == null) return [];
    
    final stats = _reportData!.assetStats;
    return [
      {'status': 'In Use', 'count': stats['in_use'] ?? 0, 'color': Colors.blue},
      {'status': 'Available', 'count': stats['in_storage'] ?? 0, 'color': Colors.green},
      {'status': 'In Repair', 'count': stats['in_repair'] ?? 0, 'color': Colors.orange},
      {'status': 'Retired', 'count': stats['retired'] ?? 0, 'color': Colors.red},
    ];
  }

  double _calculateResolutionRate(Map<String, dynamic> ticketStats) {
    final total = ticketStats['total'] ?? 0;
    final resolved = ticketStats['resolved'] ?? 0;
    final closed = ticketStats['closed'] ?? 0;
    
    if (total == 0) return 0.0;
    return ((resolved + closed) / total * 100);
  }

  double _calculateUtilizationRate(Map<String, dynamic> assetStats) {
    final total = assetStats['total_assets'] ?? 0;
    final inUse = assetStats['in_use'] ?? 0;
    
    if (total == 0) return 0.0;
    return (inUse / total * 100);
  }

  double _calculateAvgResolutionTime(Map<String, dynamic> ticketStats) {
    return (ticketStats['avg_resolution_hours'] ?? 0).toDouble();
  }

  double _calculateCriticalTicketPercentage(Map<String, dynamic> ticketStats) {
    final total = ticketStats['total'] ?? 0;
    final critical = ticketStats['critical'] ?? 0;
    
    if (total == 0) return 0.0;
    return (critical / total * 100);
  }
}