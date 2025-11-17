import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

          // Navigation Items - Role Based
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Always show these items
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.computer,
                  title: 'Assets',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/assets');
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.confirmation_number,
                  title: 'Tickets',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/tickets');
                  },
                ),

                // ADMIN ONLY SECTION
                if (user?.isAdmin == true) ...[
                  const Divider(),
                  _buildSectionHeader('Administration'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'User Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Role Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/roles');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics,
                    title: 'System Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/analytics');
                    },
                  ),
                ],

                // IT STAFF SECTION
                if (user?.isITStaff == true) ...[
                  const Divider(),
                  _buildSectionHeader('IT Management'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_accounts,
                    title: 'Manage Users',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.assignment_turned_in,
                    title: 'Assign Tickets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ticket-assignment');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.build,
                    title: 'Service Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/service-management');
                    },
                  ),
                ],

                // STAFF/TEAM LEAD SECTION
                if (user?.isStaff == true) ...[
                  const Divider(),
                  _buildSectionHeader('Team Management'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group,
                    title: 'My Team',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-team');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.assignment_ind,
                    title: 'Ticket Verification',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ticket-verification');
                    },
                  ),
                ],

                // AGENT SECTION
                if (user?.isAgent == true) ...[
                  const Divider(),
                  _buildSectionHeader('My Work'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.assignment,
                    title: 'My Tickets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-tickets');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.computer,
                    title: 'My Assets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-assets');
                    },
                  ),
                ],

                // VIEWER SECTION (Limited Access)
                if (user?.isViewer == true) ...[
                  const Divider(),
                  _buildSectionHeader('View Only'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.visibility,
                    title: 'View Assets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/view-assets');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.visibility,
                    title: 'View Tickets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/view-tickets');
                    },
                  ),
                ],

                // COMMON FEATURES FOR ALL ROLES
                const Divider(),
                _buildSectionHeader('General'),

                // Notifications (all roles except maybe viewers)
                if (user?.isViewer == false)
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    badgeCount: 0, // We'll implement this later
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),

                // Reports (Admin, IT, Staff)
                if (user?.isAdmin == true || user?.isITStaff == true || user?.isStaff == true)
                  _buildDrawerItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),

                // Settings
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),

                // Help & Support
                _buildDrawerItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help');
                  },
                ),
              ],
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

  // Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
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
}