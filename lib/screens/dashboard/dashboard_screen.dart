//filename: lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await dashboardProvider.loadDashboardData(authProvider.authData!.token);
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await dashboardProvider.refreshData(authProvider.authData!.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: dashboardProvider.isLoading ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(context, authProvider),
                    
                    const SizedBox(height: 20),

                    // Quick Stats Section
                    _buildStatsSection(context, dashboardProvider),
                    
                    const SizedBox(height: 20),

                    // Recent Activity Section
                    _buildRecentActivitySection(context, dashboardProvider),
                    
                    const SizedBox(height: 20),

                    // Assets Needing Service Section
                    if (dashboardProvider.assetsNeedingService.isNotEmpty)
                      _buildAssetsNeedingServiceSection(context, dashboardProvider),
                    
                    const SizedBox(height: 20),

                    // Quick Actions Section
                    if (authProvider.currentUser?.isAdmin == true ||
                        authProvider.currentUser?.isITStaff == true)
                      _buildQuickActionsSection(context, authProvider),
                  ],
                ),
              ),
            ),
    );
  }

  // Welcome Section
  Widget _buildWelcomeSection(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${authProvider.currentUser?.fullName ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with your inventory today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            // System Status
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  'All systems operational',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Stats Section
  Widget _buildStatsSection(BuildContext context, DashboardProvider dashboardProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              context,
              title: 'Total Assets',
              value: dashboardProvider.totalAssets.toString(),
              subtitle: '${dashboardProvider.assetsInUse} in use',
              icon: Icons.computer,
              color: Colors.blue,
              onTap: () {
                // Navigate to assets
              },
            ),
            _buildStatCard(
              context,
              title: 'Active Tickets',
              value: dashboardProvider.openTickets.toString(),
              subtitle: '${dashboardProvider.criticalTickets} critical',
              icon: Icons.confirmation_number,
              color: Colors.orange,
              onTap: () {
                // Navigate to tickets
              },
            ),
            _buildStatCard(
              context,
              title: 'In Storage',
              value: dashboardProvider.assetsInStorage.toString(),
              subtitle: 'Available assets',
              icon: Icons.warehouse,
              color: Colors.green,
              onTap: () {
                // Navigate to available assets
              },
            ),
            _buildStatCard(
              context,
              title: 'Needs Service',
              value: dashboardProvider.assetsNeedingServiceCount.toString(),
              subtitle: 'Require maintenance',
              icon: Icons.build,
              color: Colors.red,
              onTap: () {
                // Navigate to assets needing service
              },
            ),
          ],
        ),
      ],
    );
  }

  // Recent Activity Section
  Widget _buildRecentActivitySection(BuildContext context, DashboardProvider dashboardProvider) {
    final recentTickets = dashboardProvider.recentTickets.take(3).toList();
    final recentAssets = dashboardProvider.recentAssets.take(2).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (recentTickets.isNotEmpty) ...[
              ...recentTickets.map((ticket) => _buildActivityItem(
                'New Ticket: ${ticket.title}',
                'Ticket #${ticket.ticketNum}',
                Icons.confirmation_number,
                _getTicketStatusColor(ticket.status),
              )),
              const SizedBox(height: 8),
            ],

            if (recentAssets.isNotEmpty) ...[
              ...recentAssets.map((asset) => _buildActivityItem(
                'Asset Added: ${asset.internalId}',
                '${asset.manufacturer} ${asset.model}',
                Icons.computer,
                Colors.blue,
              )),
              const SizedBox(height: 8),
            ],

            if (recentTickets.isEmpty && recentAssets.isEmpty)
              _buildActivityItem(
                'No recent activity',
                'Activity will appear here',
                Icons.info,
                Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  // Assets Needing Service Section
  Widget _buildAssetsNeedingServiceSection(BuildContext context, DashboardProvider dashboardProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assets Needing Service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dashboardProvider.assetsNeedingService.take(3).map((asset) => 
              ListTile(
                leading: Icon(Icons.build, color: Colors.orange),
                title: Text(asset.internalId),
                subtitle: Text('${asset.assetType} • ${asset.model}'),
                trailing: Text(
                  'Service Due',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              )
            ),
          ],
        ),
      ),
    );
  }

  
 //  QuckActions Section - Role Based
Widget _buildQuickActionsSection(BuildContext context, AuthProvider authProvider) {
  final user = authProvider.currentUser;
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Common actions for all roles
              _buildActionChip(
                'View Assets',
                Icons.computer,
                () {
                  Navigator.pushNamed(context, '/assets');
                },
              ),
              _buildActionChip(
                'View Tickets',
                Icons.list_alt,
                () {
                  Navigator.pushNamed(context, '/tickets');
                },
              ),

              // Admin specific actions
              if (user?.isAdmin == true) ...[
                _buildActionChip(
                  'Manage Users',
                  Icons.people,
                  () {
                    Navigator.pushNamed(context, '/users');
                  },
                ),
                _buildActionChip(
                  'System Analytics',
                  Icons.analytics,
                  () {
                    Navigator.pushNamed(context, '/analytics');
                  },
                ),
              ],

              // IT Staff specific actions
              if (user?.isITStaff == true) ...[
                _buildActionChip(
                  'Assign Tickets',
                  Icons.assignment_turned_in,
                  () {
                    Navigator.pushNamed(context, '/ticket-assignment');
                  },
                ),
                _buildActionChip(
                  'Service Management',
                  Icons.build,
                  () {
                    Navigator.pushNamed(context, '/service-management');
                  },
                ),
              ],

              // Staff/Team Lead specific actions
              if (user?.isStaff == true) ...[
                _buildActionChip(
                  'My Team',
                  Icons.group,
                  () {
                    Navigator.pushNamed(context, '/my-team');
                  },
                ),
                _buildActionChip(
                  'Verify Tickets',
                  Icons.assignment_ind,
                  () {
                    Navigator.pushNamed(context, '/ticket-verification');
                  },
                ),
              ],

              // Agent specific actions
              if (user?.isAgent == true) ...[
                _buildActionChip(
                  'My Tickets',
                  Icons.assignment,
                  () {
                    Navigator.pushNamed(context, '/my-tickets');
                  },
                ),
                _buildActionChip(
                  'My Assets',
                  Icons.computer,
                  () {
                    Navigator.pushNamed(context, '/my-assets');
                  },
                ),
              ],

              // Create actions for users who can create content
              if (user?.isViewer == false) ...[
                _buildActionChip(
                  'Create Ticket',
                  Icons.add_task,
                  () {
                    // Will implement ticket creation later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket creation coming soon!')),
                    );
                  },
                ),
              ],

              // Asset creation for Admin and IT
              if (user?.isAdmin == true || user?.isITStaff == true)
                _buildActionChip(
                  'Add Asset',
                  Icons.add,
                  () {
                    // Will implement asset creation later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Asset creation coming soon!')),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // Helper method to build stat cards
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build activity items
  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
    );
  }

  // Helper method to build action chips
  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue[50],
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }

  // Helper method to get ticket status color
  Color _getTicketStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

// 