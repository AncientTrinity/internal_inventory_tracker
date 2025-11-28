// filename: lib/screens/notifications/notification_list_screen.dart
import 'package:flutter/material.dart' hide Notification;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/user_provider.dart';
import '../assets/asset_detail_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import '../users/user_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.authData != null) {
      setState(() => _isRefreshing = true);
      await notificationProvider.loadNotifications(authProvider.authData!.token);
      await notificationProvider.loadUnreadCount(authProvider.authData!.token);
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _markAsRead(Notification notification) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      await notificationProvider.markAsRead(notification.id, authProvider.authData!.token);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      await notificationProvider.markAllAsRead(authProvider.authData!.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildNotificationItem(Notification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: notification.relatedId != null && notification.relatedType != null 
              ? Border.all(color: notification.color, width: 2)
              : null,
          ),
          child: Center(
            child: Text(
              notification.icon,
              style: TextStyle(
                fontSize: 16,
                color: notification.relatedId != null && notification.relatedType != null 
                  ? notification.color 
                  : Colors.grey[600],
              ),
            ),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: notification.isRead ? Colors.grey[600] : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(
                color: notification.isRead ? Colors.grey[600] : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
          if (notification.relatedId != null && notification.relatedType != null) {
            _navigateToRelatedItem(notification);
          }
        },
        onLongPress: () {
          _showNotificationActions(notification);
        },
      ),
    );
  }

  void _showNotificationActions(Notification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mark_email_read),
            title: const Text('Mark as Read'),
            onTap: () {
              Navigator.pop(context);
              _markAsRead(notification);
            },
          ),
          if (notification.relatedId != null && notification.relatedType != null)
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text('View ${_getRelatedTypeName(notification.relatedType!)}'),
              onTap: () {
                Navigator.pop(context);
                _navigateToRelatedItem(notification);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getRelatedTypeName(String relatedType) {
    switch (relatedType) {
      case 'ticket':
        return 'Ticket';
      case 'asset':
        return 'Asset';
      case 'user':
        return 'User';
      default:
        return 'Item';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!\nNew notifications will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarActions(NotificationProvider notificationProvider) {
    final hasUnread = notificationProvider.notifications.any((n) => !n.isRead);
    
    return Row(
      children: [
        if (hasUnread)
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshNotifications,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _buildAppBarActions(notificationProvider),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: notificationProvider.notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: notificationProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notificationProvider.notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
    );
  }

  void _navigateToRelatedItem(Notification notification) {
    if (notification.relatedType == 'ticket' && notification.relatedId != null) {
      _navigateToTicket(notification.relatedId!, notification);
    } else if (notification.relatedType == 'asset' && notification.relatedId != null) {
      _navigateToAsset(notification.relatedId!, notification);
    } else if (notification.relatedType == 'user' && notification.relatedId != null) {
      _navigateToUser(notification.relatedId!, notification);
    } else {
      // Generic notification - just mark as read
      if (!notification.isRead) {
        _markAsRead(notification);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No related item to navigate to'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToTicket(int ticketId, Notification notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _markAsRead(notification);
    }
    
    // Show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening ticket...'),
        duration: Duration(milliseconds: 800),
      ),
    );
    
    // Small delay for user to see feedback
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navigate to ticket detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticketId),
      ),
    );
  }

  Future<void> _navigateToAsset(int assetId, Notification notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _markAsRead(notification);
    }
    
    // Show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening asset...'),
        duration: Duration(milliseconds: 800),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navigate to asset detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetDetailScreen(assetId: assetId),
      ),
    );
  }

  Future<void> _navigateToUser(int userId, Notification notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _markAsRead(notification);
    }
    
    // Show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening user profile...'),
        duration: Duration(milliseconds: 800),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Navigate to user detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userId: userId),
      ),
    );
  }
}