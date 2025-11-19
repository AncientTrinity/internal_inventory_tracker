//filename: lib/widgets/navbar/navbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          // User Accounts Drawer Header
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'No email',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),

          // Role Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: _getRoleColor(user?.roleId ?? 0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getRoleIcon(user?.roleId ?? 0),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.roleName.toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ========== NAVIGATION ITEMS ==========
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildNavigationItems(context, user),
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // Close drawer
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build navigation items based on user role
  List<Widget> _buildNavigationItems(BuildContext context, User? user) {
    if (user?.isAgent == true) {
      // AGENT-ONLY NAVIGATION
      return [
        _buildDrawerItem(
          context,
          icon: Icons.dashboard,
          title: 'Dashboard',
          onTap: () => _navigateTo(context, '/dashboard'),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.devices_other,
          title: 'My Assigned Assets',
          onTap: () => _navigateTo(context, '/my-assets'),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.assignment,
          title: 'My Support Tickets',
          onTap: () => _navigateTo(context, '/my-tickets'),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          badgeCount: _getUnreadNotificationCount(user),
          onTap: () => _navigateTo(context, '/notifications'),
        ),
        const Divider(),
        _buildDrawerItem(
          context,
          icon: Icons.person,
          title: 'My Profile',
          onTap: () => _navigateTo(context, '/profile'),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.help,
          title: 'Help & Support',
          onTap: () => _navigateTo(context, '/help'),
        ),
      ];
    } else {
      // ALL OTHER ROLES NAVIGATION
      List<Widget> items = [
        _buildDrawerItem(
          context,
          icon: Icons.dashboard,
          title: 'Dashboard',
          onTap: () => _navigateTo(context, '/dashboard'),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.computer,
          title: 'Assets',
          onTap: () => _navigateTo(context, '/assets'),
        ),
      ];

      // Add Tickets for authorized non-agents
      if (user?.canViewAllTickets == true || user?.isViewer == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.confirmation_number,
            title: 'Tickets',
            onTap: () => _navigateTo(context, '/tickets'),
          ),
        );
      }

      // Add role-specific features for non-agents
      if (user?.isStaff == true) {
        items.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.groups,
            title: 'My Team',
            onTap: () => _navigateTo(context, '/my-team'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.verified,
            title: 'Ticket Verification',
            onTap: () => _navigateTo(context, '/ticket-verification'),
          ),
        ]);
      }

      if (user?.isAdmin == true || user?.isITStaff == true) {
        items.addAll([
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'User Management',
            onTap: () => _navigateTo(context, '/users'),
          ),
        ]);
      }

      if (user?.isAdmin == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.admin_panel_settings,
            title: 'Role Management',
            onTap: () => _navigateTo(context, '/roles'),
          ),
        );
      }

      if (user?.isITStaff == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.build,
            title: 'Service Management',
            onTap: () => _navigateTo(context, '/service-management'),
          ),
        );
      }

      if (user?.isAdmin == true || user?.isITStaff == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () => _navigateTo(context, '/analytics'),
          ),
        );
      }

      if (user?.canViewAllTickets == true || user?.isStaff == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () => _navigateTo(context, '/reports'),
          ),
        );
      }

      // Add common features
      items.addAll([
        _buildDrawerItem(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          badgeCount: _getUnreadNotificationCount(user),
          onTap: () => _navigateTo(context, '/notifications'),
        ),
        const Divider(),
        _buildDrawerItem(
          context,
          icon: Icons.person,
          title: 'My Profile',
          onTap: () => _navigateTo(context, '/profile'),
        ),
      ]);

      if (user?.isAdmin == true || user?.isITStaff == true) {
        items.add(
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'System Settings',
            onTap: () => _navigateTo(context, '/settings'),
          ),
        );
      }

      items.add(
        _buildDrawerItem(
          context,
          icon: Icons.help,
          title: 'Help & Support',
          onTap: () => _navigateTo(context, '/help'),
        ),
      );

      return items;
    }
  }

  // Helper method for navigation
  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, route);
  }

  // Helper method to build drawer items
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        int badgeCount = 0,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: badgeCount > 0
          ? Container(
        padding: const EdgeInsets.all(4.0),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          badgeCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      onTap: onTap,
    );
  }

  // Helper method to get role color
  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: // Admin
        return Colors.red;
      case 2: // IT Staff
        return Colors.orange;
      case 3: // Staff/Team Lead
        return Colors.green;
      case 4: // Agent
        return Colors.blue;
      case 5: // Viewer
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // Helper method to get role icon
  IconData _getRoleIcon(int roleId) {
    switch (roleId) {
      case 1: // Admin
        return Icons.security;
      case 2: // IT Staff
        return Icons.computer;
      case 3: // Staff/Team Lead
        return Icons.leaderboard;
      case 4: // Agent
        return Icons.support_agent;
      case 5: // Viewer
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  // Helper method to get unread notification count
  int _getUnreadNotificationCount(User? user) {
    // TODO: Implement actual notification count from provider
    // For now, return 0
    return 0;
  }
}