//filename: lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/asset.dart';
import '../../screens/assets/asset_detail_screen.dart';
import '../../screens/tickets/ticket_detail_screen.dart';
import '../../screens/notifications/notification_list_screen.dart';

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
    _loadInitialData();
     WidgetsBinding.instance.addPostFrameCallback((_) {
    print('🌤️ Dashboard: Loading weather data...');
    _loadDashboardData();
  });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    if (authProvider.authData != null) {
      try {
        // Pass current user to dashboard provider
        await dashboardProvider.loadDashboardData(
          authProvider.authData!.token,
          authProvider.currentUser, // ADD THIS
        );
        await ticketProvider.loadTickets(authProvider.authData!.token);
      } catch (e) {
        print('Error loading dashboard data: $e');
        // Don't show error to user for dashboard, just use empty data
      }
    }
  }

  Future<void> _loadInitialData() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  
  if (authProvider.authData != null) {
    await notificationProvider.loadUnreadCount(authProvider.authData!.token);
  }
}

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false); // ADD THIS

    if (authProvider.authData != null) {
      // Pass current user to dashboard provider
      await dashboardProvider.refreshData(
        authProvider.authData!.token,
        authProvider.currentUser, // ADD THIS
      );
      await ticketProvider.loadTickets(authProvider.authData!.token);
      await notificationProvider.loadUnreadCount(authProvider.authData!.token); // ADD THIS
    }
  }

  // ADD THIS: Build notification bell with badge
  Widget _buildNotificationBell() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationListScreen(),
                  ),
                );
              },
              tooltip: 'Notifications',
            ),
            if (notificationProvider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    notificationProvider.unreadCount > 99 
                        ? '99+' 
                        : notificationProvider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  // Agent-Specific Dashboard
  Widget _buildAgentDashboard(DashboardProvider dashboardProvider, User currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome message for agent
        _buildAgentWelcomeSection(currentUser),
        const SizedBox(height: 20),

        // Agent Statistics Cards
        _buildAgentStatisticsSection(dashboardProvider),
        const SizedBox(height: 20),

        // Agent's Assets Section
        if (dashboardProvider.agentAssets.isNotEmpty)
          _buildAgentAssetsSection(dashboardProvider),

        // Agent's Active Tickets Section
        if (dashboardProvider.agentTickets.isNotEmpty)
          _buildAgentTicketsSection(dashboardProvider),

        // Empty state if no assets or tickets
        if (dashboardProvider.agentAssets.isEmpty && dashboardProvider.agentTickets.isEmpty)
          _buildAgentEmptyState(),

          _buildWeatherCard(),
          const SizedBox(height: 20),
        
      ],
    );
  }

  // Full Dashboard for Admin/IT/Staff
  Widget _buildFullDashboard(BuildContext context, DashboardProvider dashboardProvider, AuthProvider authProvider) {

     // Check if there's any data to show
  final hasData = dashboardProvider.totalAssets > 0 || 
                  dashboardProvider.totalTickets > 0 ||
                  dashboardProvider.recentAssets.isNotEmpty ||
                  dashboardProvider.recentTickets.isNotEmpty;

  if (!hasData) {
    return _buildEmptyDashboardState(
      'Welcome to your Dashboard!',
      subtitle: 'Start by adding assets or creating tickets to see analytics here.',
    );
  }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        _buildWelcomeSection(context, authProvider),
        const SizedBox(height: 20),

        // Quick Stats Section
        _buildStatsSection(context, dashboardProvider),
        const SizedBox(height: 20),

        // Ticket Stats Section
        _buildTicketStats(),
        const SizedBox(height: 20),

        // Recent Activity Section
        _buildRecentActivitySection(context, dashboardProvider),
        const SizedBox(height: 20),

        // Assets Needing Service Section
        if (dashboardProvider.assetsNeedingService.isNotEmpty)
          _buildAssetsNeedingServiceSection(context, dashboardProvider),

        const SizedBox(height: 20),

        _buildWeatherCard(),
        const SizedBox(height: 20),

        // Quick Actions Section
        if (authProvider.currentUser?.isAdmin == true ||
            authProvider.currentUser?.isITStaff == true)
          _buildQuickActionsSection(context, authProvider),
      ],
    );
  }

  // ========== AGENT-SPECIFIC WIDGETS ==========

  Widget _buildAgentWelcomeSection(User currentUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Text(
                currentUser.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${currentUser.fullName}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s your equipment and support requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentStatisticsSection(DashboardProvider dashboardProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'My Assets',
            value: dashboardProvider.agentTotalAssets.toString(),
            subtitle: 'Assigned to you',
            icon: Icons.computer,
            color: Colors.blue,
            onTap: () {
              Navigator.pushNamed(context, '/my-assets');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Active Tickets',
            value: dashboardProvider.agentActiveTickets.toString(),
            subtitle: 'Requiring attention',
            icon: Icons.confirmation_number,
            color: Colors.orange,
            onTap: () {
              Navigator.pushNamed(context, '/tickets');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentAssetsSection(DashboardProvider dashboardProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Assigned Assets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...dashboardProvider.agentAssets.take(3).map((asset) =>
            _buildAssetListItem(asset)
        ).toList(),
        if (dashboardProvider.agentAssets.length > 3)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/my-assets');
            },
            child: const Text('View All Assets'),
          ),
      ],
    );
  }

  Widget _buildAssetListItem(Asset asset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getAssetTypeIcon(asset.assetType),
          color: _getAssetStatusColor(asset.status),
        ),
        title: Text(asset.internalId),
        subtitle: Text('${asset.manufacturer} ${asset.model} • ${asset.statusDisplay}'),
        trailing: asset.needsService
            ? const Icon(Icons.warning, color: Colors.orange)
            : null,
        onTap: () {
          // Navigate to asset detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(assetId: asset.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentTicketsSection(DashboardProvider dashboardProvider) {
    final activeTickets = dashboardProvider.agentTickets
        .where((ticket) => ticket.isOpen || ticket.isReceived || ticket.isInProgress)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Active Tickets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (activeTickets.isEmpty)
          const Text(
            'No active tickets',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...activeTickets.take(3).map((ticket) =>
              _buildTicketListItem(ticket)
          ).toList(),
        if (dashboardProvider.agentTickets.length > 3)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/tickets');
            },
            child: const Text('View All Tickets'),
          ),
      ],
    );
  }

  Widget _buildTicketListItem(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ticket.statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTicketTypeIcon(ticket.type),
            color: ticket.statusColor,
          ),
        ),
        title: Text(ticket.title),
        subtitle: Text('${_getTicketStatusDisplay(ticket.status)} • ${_getTicketPriorityDisplay(ticket.priority)}'),
        trailing: Text(
          ticket.completion.toInt().toString() + '%',
          style: TextStyle(
            color: ticket.statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Assets Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have any assets assigned to you yet.\nContact your Team Lead or IT department.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
   
   //for weather card
 Widget _buildWeatherCard() {
  final dashboardProvider = Provider.of<DashboardProvider>(context);
  final weatherData = dashboardProvider.weatherData;

  if (dashboardProvider.isLoading && weatherData == null) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loading weather...', style: Theme.of(context).textTheme.titleMedium),
                Text('Fetching current conditions', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  if (weatherData == null) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[400]),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather unavailable', style: Theme.of(context).textTheme.titleMedium),
                Text('Check connection', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location and update time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Weather',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                weatherData.iconUrl ?? '🌤️',
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weatherData.location,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Main weather info
          Row(
            children: [
              // Temperature (large and prominent)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    weatherData.condition,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${weatherData.feelsLike.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Weather metrics
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${weatherData.humidity.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Humidity',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${weatherData.windSpeed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Wind',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Update time
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Updated: ${weatherData.updateTime}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  // ========== HELPER METHODS ==========

  IconData _getAssetTypeIcon(String assetType) {
    switch (assetType) {
      case 'PC': return Icons.computer;
      case 'MONITOR': return Icons.monitor;
      case 'KEYBOARD': return Icons.keyboard;
      case 'MOUSE': return Icons.mouse;
      case 'HEADSET': return Icons.headset;
      case 'UPS': return Icons.power;
      default: return Icons.devices_other;
    }
  }

  IconData _getTicketTypeIcon(String type) {
    switch (type) {
      case 'it_help': return Icons.help;
      case 'activation': return Icons.play_arrow;
      case 'deactivation': return Icons.stop;
      case 'transition': return Icons.swap_horiz;
      default: return Icons.confirmation_number;
    }
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
  Widget _buildStatsSection(
      BuildContext context, DashboardProvider dashboardProvider) {
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
                Navigator.pushNamed(context, '/assets');
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
                Navigator.pushNamed(context, '/tickets');
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
  Widget _buildRecentActivitySection(
      BuildContext context, DashboardProvider dashboardProvider) {
    final recentTickets = dashboardProvider.recentTickets.take(3).toList();
    final recentAssets = dashboardProvider.recentAssets.take(2).toList();
    final hasActivity = recentTickets.isNotEmpty || recentAssets.isNotEmpty;

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
                const Spacer(),
                if (!hasActivity)
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasActivity) ...[
              if (recentTickets.isNotEmpty) ...[
                ...recentTickets.map((ticket) => _buildActivityItem(
                      '${ticket.statusDisplay}: ${ticket.title}',
                      'Priority: ${ticket.priorityDisplay}',
                      Icons.confirmation_number,
                      _getTicketStatusColor(ticket.status),
                    )),
                if (recentAssets.isNotEmpty) const SizedBox(height: 8),
              ],
              if (recentAssets.isNotEmpty) ...[
                ...recentAssets.map((asset) => _buildActivityItem(
                      'Asset: ${asset.internalId}',
                      '${asset.manufacturer} ${asset.model}',
                      Icons.computer,
                      Colors.blue,
                    )),
              ],
            ] else ...[
              _buildEmptyActivityItem(),
            ],
          ],
        ),
      ),
    );
  }

  // Add this helper method for empty state
Widget _buildEmptyActivityItem() {
  return Column(
    children: [
      Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 8),
      Text(
        'No recent activity',
        style: TextStyle(color: Colors.grey[500]),
      ),
      Text(
        'Activity will appear here as it happens',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    ],
  );
}

  // Assets Needing Service Section
  Widget _buildAssetsNeedingServiceSection(
      BuildContext context, DashboardProvider dashboardProvider) {
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
            ...dashboardProvider.assetsNeedingService
                .take(3)
                .map((asset) => ListTile(
                      leading: Icon(Icons.build, color: Colors.orange),
                      title: Text(asset.internalId),
                      subtitle: Text('${asset.assetType} • ${asset.model}'),
                      trailing: Text(
                        'Service Due',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      contentPadding: EdgeInsets.zero,
                      visualDensity:
                          const VisualDensity(horizontal: 0, vertical: -4),
                    )),
          ],
        ),
      ),
    );
  }

  //  QuckActions Section - Role Based
  Widget _buildQuickActionsSection(
      BuildContext context, AuthProvider authProvider) {
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

                // Create actions for users who can create content
                if (user?.isViewer == false)
                  _buildActionChip(
                    'Create Ticket',
                    Icons.add_task,
                    () {
                      Navigator.pushNamed(
                          context, '/tickets/create'); // UPDATED
                    },
                  ),

                // Asset creation for Admin and IT
                if (user?.isAdmin == true || user?.isITStaff == true)
                  _buildActionChip(
                    'Add Asset',
                    Icons.add,
                    () {
                      Navigator.pushNamed(context, '/assets/add'); // UPDATED
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
                      Navigator.pushNamed(context, '/reports');
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
                        const SnackBar(
                            content: Text('Ticket creation coming soon!')),
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
                        const SnackBar(
                            content: Text('Asset creation coming soon!')),
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
  Widget _buildActivityItem(
      String title, String subtitle, IconData icon, Color color) {
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


// Add this to your dashboard_screen.dart to show ticket statistics:

  Widget _buildTicketStats() {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUser = authProvider.currentUser;

        // Get analytics based on user role
        final analytics = ticketProvider.getTicketAnalytics();
        final userTickets =
            _getUserSpecificTickets(ticketProvider, currentUser);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Ticket Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (currentUser?.canViewAllTickets == true)
                      Text(
                        '${analytics['resolution_rate']?.toStringAsFixed(1) ?? '0'}% Resolved',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats based on user role
                if (currentUser?.canViewAllTickets == true)
                  _buildAdminTicketStats(ticketProvider, analytics)
                else
                  _buildUserTicketStats(userTickets, currentUser),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tickets');
                  },
                  icon: const Icon(Icons.confirmation_number),
                  label: const Text('View All Tickets'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper method for admin/IT/staff view
  Widget _buildAdminTicketStats(
      TicketProvider ticketProvider, Map<String, dynamic> analytics) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                'Open',
                ticketProvider.getTicketsByStatus('OPEN').length,
                Colors.orange),
            _buildStatItem(
                'In Progress',
                ticketProvider.getTicketsByStatus('IN_PROGRESS').length,
                Colors.purple),
            _buildStatItem(
                'Resolved',
                ticketProvider.getTicketsByStatus('RESOLVED').length,
                Colors.green),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                'Critical',
                ticketProvider.getTicketsByPriority('critical').length,
                Colors.red),
            _buildStatItem(
                'High',
                ticketProvider.getTicketsByPriority('high').length,
                Colors.orange),
            _buildStatItem('Total', ticketProvider.tickets.length, Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        if (analytics['avg_resolution_time'] > 0)
          Text(
            'Avg. Resolution: ${analytics['avg_resolution_time'].toStringAsFixed(1)} hours',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

// Helper method for agent/viewer view
  Widget _buildUserTicketStats(List<Ticket> userTickets, User? currentUser) {
    final myOpenTickets = userTickets
        .where((t) => t.isOpen || t.isReceived || t.isInProgress)
        .length;
    final myResolvedTickets =
        userTickets.where((t) => t.isResolved || t.isClosed).length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('My Open', myOpenTickets, Colors.orange),
            _buildStatItem('My Resolved', myResolvedTickets, Colors.green),
            _buildStatItem('Total', userTickets.length, Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        if (currentUser?.isAgent == true)
          Text(
            'Tickets linked to your assets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

// Helper method to get user-specific tickets
  List<Ticket> _getUserSpecificTickets(
      TicketProvider ticketProvider, User? currentUser) {
    if (currentUser == null) return [];

    if (currentUser.canViewAllTickets) {
      return ticketProvider.tickets;
    } else if (currentUser.isAgent) {
      return ticketProvider.tickets.where((ticket) {
        final isCreatedByAgent = ticket.createdBy == currentUser.id;
        // For now, return tickets created by agent until we implement asset linking
        return isCreatedByAgent;
      }).toList();
    }

    return [];
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

// Add these missing methods to your dashboard_screen.dart

// Helper method to get asset status color
Color _getAssetStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return Colors.green;
    case 'assigned':
      return Colors.blue;
    case 'in_repair':
      return Colors.orange;
    case 'retired':
      return Colors.grey;
    default:
      return Colors.blue;
  }
}

// Helper method to get asset status display text
String _getAssetStatusDisplay(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return 'Available';
    case 'assigned':
      return 'Assigned';
    case 'in_repair':
      return 'In Repair';
    case 'retired':
      return 'Retired';
    default:
      return status;
  }
}

// Helper method to get ticket priority display
String _getTicketPriorityDisplay(String priority) {
  switch (priority.toLowerCase()) {
    case 'low':
      return 'Low';
    case 'normal':
      return 'Normal';
    case 'high':
      return 'High';
    case 'critical':
      return 'Critical';
    default:
      return priority;
  }
}

// Helper method to get ticket status display
String _getTicketStatusDisplay(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return 'Open';
    case 'received':
      return 'Received';
    case 'in_progress':
      return 'In Progress';
    case 'resolved':
      return 'Resolved';
    case 'closed':
      return 'Closed';
    default:
      return status;
  }
}

// Helper method to get ticket status color
Color _getTicketStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return Colors.orange;
    case 'received':
      return Colors.blue;
    case 'in_progress':
      return Colors.purple;
    case 'resolved':
      return Colors.green;
    case 'closed':
      return Colors.grey;
    default:
      return Colors.blue;
  }
}

// Add this method to handle empty states gracefully
Widget _buildEmptyDashboardState(String message, {String? subtitle}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.dashboard,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

// Add error state widget
Widget _buildErrorState(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load dashboard',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _refreshData,
          child: const Text('Try Again'),
        ),
      ],
    ),
  );
}

// Update your build method to handle error states
@override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  final dashboardProvider = Provider.of<DashboardProvider>(context);
  final currentUser = authProvider.currentUser;

  // Handle loading state
  if (dashboardProvider.isLoading) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // Handle error state
  if (dashboardProvider.error != null) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildErrorState(dashboardProvider.error!),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        _buildNotificationBell(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Refresh Data',
        ),
      ],
    ),
    drawer: const AppDrawer(),
    body: RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentUser?.isAgent == true)
              _buildAgentDashboard(dashboardProvider, currentUser!)
            else
              _buildFullDashboard(context, dashboardProvider, authProvider),
          ],
        ),
      ),
    ),
  );
}

// Add this method to your Dashboard, Ticket screens, etc.
Future<void> _refreshNotifications() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  
  if (authProvider.authData != null) {
    await notificationProvider.loadUnreadCount(authProvider.authData!.token);
  }
}

// Call this after creating a ticket, updating status, etc.
// Example in your ticket creation method:
 // Add this after successful ticket creation

}