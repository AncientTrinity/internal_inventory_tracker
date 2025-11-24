// filename: lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications(String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    // ✅ FIX: Use Future.microtask to defer notifications until after build
    Future.microtask(() => notifyListeners());

    try {
      _notifications = await _notificationService.getNotifications(token);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      // ✅ FIX: Use Future.microtask to defer notifications until after build
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> loadUnreadCount(String token) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(token);
      // ✅ FIX: Use Future.microtask to defer notifications until after build
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markAsRead(int notificationId, String token) async {
    try {
      await _notificationService.markAsRead(notificationId, token);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        // ✅ FIX: Use Future.microtask to defer notifications until after build
        Future.microtask(() => notifyListeners());
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      await _notificationService.markAllAsRead(token);
      
      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCount = 0;
      // ✅ FIX: Use Future.microtask to defer notifications until after build
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    // ✅ FIX: Use Future.microtask to defer notifications until after build
    Future.microtask(() => notifyListeners());
  }
}