// filename: lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/api_config.dart';

class NotificationService {
  
Future<List<Notification>> getNotifications(String token) async {
  try {
    print('📡 Fetching notifications from API...');
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/notifications'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    print('🔍 Notification API Response Status: ${response.statusCode}');
    print('🔍 Notification API Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = json.decode(response.body);
      print('📦 Parsed ${data.length} notifications from API');
      return data.map((item) => Notification.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Failed to load notifications: $e');
    throw Exception('Failed to load notifications: $e');
  }
}

 Future<int> getUnreadCount(String token) async {
  try {
    print('📡 Fetching unread count from API...');
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/notifications/unread-count'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = json.decode(response.body);
      final count = data['unread_count'] ?? 0;
      print('🔔 Unread count from API: $count');
      return count;
    } else {
      throw Exception('Failed to load unread count: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Failed to load unread count: $e');
    throw Exception('Failed to load unread count: $e');
  }
}

  Future<void> markAsRead(int notificationId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/notifications/$notificationId/read'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/notifications/read-all'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  Future<List<String>> getNotificationTypes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/notifications/types'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> types = data['types'] ?? [];
        return types.map((type) => type.toString()).toList();
      } else {
        throw Exception('Failed to load notification types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load notification types: $e');
    }
  }
}