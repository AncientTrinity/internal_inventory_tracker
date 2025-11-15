import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/ticket_provider.dart';
import 'package:internal_inventory_tracker/models/ticket.dart';
import 'package:internal_inventory_tracker/models/asset.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    
    await Future.wait([
      assetProvider.loadAssetStats(),
      ticketProvider.loadTicketStats(),
      assetProvider.loadAssets(),
      ticketProvider.loadTickets(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assetProvider = Provider.of<AssetProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(authProvider, assetProvider, ticketProvider),
    );
  }

  Widget _buildBody(AuthProvider auth, AssetProvider assets, TicketProvider tickets) {
    if (assets.isLoading || tickets.isLoading) {
      return const LoadingIndicator(); // This will now work
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(auth),
            const SizedBox(height: 24),
            _buildStatsSection(assets, tickets),
            const SizedBox(height: 24),
            _buildQuickActions(auth),
            const SizedBox(height: 24),
            _buildRecentTickets(tickets),
            const SizedBox(height: 24),
            _buildAssetOverview(assets),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider auth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${auth.user?.fullName ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.user?.roleDisplay ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(AssetProvider assets, TicketProvider tickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              title: 'Total Assets',
              value: assets.stats?.totalAssets.toString() ?? '0',
              icon: Icons.devices,
              color: Colors.blue,
              subtitle: '${assets.stats?.inUse ?? 0} in use',
            ),
            _buildStatCard(
              title: 'Active Tickets',
              value: tickets.stats?.activeTickets.toString() ?? '0',
              icon: Icons.support_agent,
              color: Colors.orange,
              subtitle: '${tickets.stats?.critical ?? 0} critical',
            ),
            _buildStatCard(
              title: 'Assets in Storage',
              value: assets.stats?.inStorage.toString() ?? '0',
              icon: Icons.warehouse,
              color: Colors.green,
              subtitle: 'Available for assignment',
            ),
            _buildStatCard(
              title: 'Needs Service',
              value: assets.stats?.needsService.toString() ?? '0',
              icon: Icons.build,
              color: Colors.red,
              subtitle: 'Requires maintenance',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (auth.canManageTickets)
              _buildActionButton(
                icon: Icons.add_task,
                label: 'New Ticket',
                color: Colors.blue,
                onTap: () => _navigateToCreateTicket(),
              ),
            if (auth.canManageAssets)
              _buildActionButton(
                icon: Icons.add_to_photos,
                label: 'Add Asset',
                color: Colors.green,
                onTap: () => _navigateToCreateAsset(),
              ),
            if (auth.canManageTickets)
              _buildActionButton(
                icon: Icons.list_alt,
                label: 'View Tickets',
                color: Colors.orange,
                onTap: () => _navigateToTickets(),
              ),
            if (auth.canManageAssets)
              _buildActionButton(
                icon: Icons.inventory_2,
                label: 'View Assets',
                color: Colors.purple,
                onTap: () => _navigateToAssets(),
              ),
            if (auth.user?.isITStaff ?? false)
              _buildActionButton(
                icon: Icons.build,
                label: 'Service Logs',
                color: Colors.red,
                onTap: () => _navigateToServiceLogs(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTickets(TicketProvider tickets) {
    final recentTickets = tickets.tickets.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Tickets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _navigateToTickets(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTickets.isEmpty)
          _buildEmptyState(
            icon: Icons.support_agent,
            message: 'No recent tickets',
            subtitle: 'Tickets you create or are assigned to will appear here',
          )
        else
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: recentTickets.map((ticket) => _buildTicketItem(ticket)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTicketItem(Ticket ticket) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getStatusColor(ticket.status).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.support_agent,
          color: _getStatusColor(ticket.status),
          size: 20,
        ),
      ),
      title: Text(
        ticket.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${ticket.ticketNum} • ${ticket.priorityDisplay}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.statusDisplay,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(ticket.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${ticket.completion}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _navigateToTicketDetail(ticket.id),
    );
  }

  Widget _buildAssetOverview(AssetProvider assets) {
    final recentAssets = assets.assets.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Asset Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _navigateToAssets(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentAssets.isEmpty)
          _buildEmptyState(
            icon: Icons.devices,
            message: 'No assets found',
            subtitle: 'Assets will appear here once added to the system',
          )
        else
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: recentAssets.map((asset) => _buildAssetItem(asset)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssetItem(Asset asset) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: asset.statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          asset.typeIcon,
          color: asset.statusColor,
          size: 20,
        ),
      ),
      title: Text(
        asset.internalId,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${asset.typeDisplay} • ${asset.manufacturer ?? 'Unknown'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: asset.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  asset.statusDisplay,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: asset.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (asset.isAssigned) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Assigned',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      onTap: () => _navigateToAssetDetail(asset.id),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'received': return Colors.orange;
      case 'in_progress': return Colors.purple;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  // Navigation methods
  void _navigateToCreateTicket() {
    // TODO: Implement navigation to create ticket screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Create Ticket')),
    );
  }

  void _navigateToCreateAsset() {
    // TODO: Implement navigation to create asset screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Create Asset')),
    );
  }

  void _navigateToTickets() {
    // TODO: Implement navigation to tickets screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Tickets')),
    );
  }

  void _navigateToAssets() {
    // TODO: Implement navigation to assets screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Assets')),
    );
  }

  void _navigateToServiceLogs() {
    // TODO: Implement navigation to service logs screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Service Logs')),
    );
  }

  void _navigateToTicketDetail(int ticketId) {
    // TODO: Implement navigation to ticket detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to Ticket #$ticketId')),
    );
  }

  void _navigateToAssetDetail(int assetId) {
    // TODO: Implement navigation to asset detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to Asset #$assetId')),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}