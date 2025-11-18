// filename: lib/providers/service_log_provider.dart
import 'package:flutter/foundation.dart';
import '../models/service_log.dart';
import '../services/service_log_service.dart';

class ServiceLogProvider with ChangeNotifier {
  final ServiceLogService _serviceLogService = ServiceLogService();
  
  List<ServiceLog> _serviceLogs = [];
  ServiceLog? _selectedServiceLog;
  bool _isLoading = false;
  String? _error;

  List<ServiceLog> get serviceLogs => _serviceLogs;
  ServiceLog? get selectedServiceLog => _selectedServiceLog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load service logs for an asset
  Future<void> loadServiceLogsForAsset(int assetId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceLogs = await _serviceLogService.getServiceLogsForAsset(assetId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new service log
  Future<void> createServiceLog(ServiceLog serviceLog, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newServiceLog = await _serviceLogService.createServiceLog(serviceLog, token);
      _serviceLogs.insert(0, newServiceLog);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a service log
  Future<void> updateServiceLog(ServiceLog serviceLog, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedServiceLog = await _serviceLogService.updateServiceLog(serviceLog, token);
      final index = _serviceLogs.indexWhere((log) => log.id == serviceLog.id);
      if (index != -1) {
        _serviceLogs[index] = updatedServiceLog;
      }
      if (_selectedServiceLog?.id == serviceLog.id) {
        _selectedServiceLog = updatedServiceLog;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a service log
  Future<void> deleteServiceLog(int logId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _serviceLogService.deleteServiceLog(logId, token);
      _serviceLogs.removeWhere((log) => log.id == logId);
      if (_selectedServiceLog?.id == logId) {
        _selectedServiceLog = null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get service log by ID
  Future<void> loadServiceLogById(int logId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedServiceLog = await _serviceLogService.getServiceLogById(logId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected service log
  void clearSelectedServiceLog() {
    _selectedServiceLog = null;
    notifyListeners();
  }

  // Get service logs that need follow-up (next service due soon)
  List<ServiceLog> getServiceLogsNeedingFollowUp() {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return _serviceLogs.where((log) {
      // This would need to be enhanced based on your business logic
      return log.serviceType == 'PREVENTIVE_MAINTENANCE';
    }).toList();
  }

  // Get recent service logs (last 30 days)
  List<ServiceLog> getRecentServiceLogs() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _serviceLogs.where((log) => log.serviceDate.isAfter(thirtyDaysAgo)).toList();
  }
}