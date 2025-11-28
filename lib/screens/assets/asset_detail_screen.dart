// filename: lib/screens/assets/asset_detail_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/service_log.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/service_log_provider.dart';
import '../../services/secure_storage_service.dart';
import '../../utils/api_config.dart';
import '../../widgets/common/app_drawer.dart';
import 'asset_form_screen.dart';
import 'service_log_form_screen.dart';
import 'service_log_list_screen.dart';
import 'schedule_service_screen.dart';
import 'user_selection_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to schedule the load after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssetDetails();
      _loadServiceLogs();
    });
  }

  Future<void> _loadAssetDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await assetProvider.loadAssetById(
          widget.assetId, authProvider.authData!.token);
    }
  }

  Future<void> _refreshAsset() async {
    await _loadAssetDetails();
  }

  void _showActionMenu() {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asset = assetProvider.selectedAsset;
    final user = authProvider.currentUser;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh'),
            onTap: () {
              Navigator.pop(context);
              _refreshAsset();
            },
          ),
          if ((user?.isAdmin == true || user?.isITStaff == true) &&
              asset != null)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Asset'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetFormScreen(asset: asset),
                  ),
                );
              },
            ),
          // Hide assign/unassign for Agents - only show for Admin/IT Staff
          if ((user?.isAdmin == true || user?.isITStaff == true) &&
              asset != null)
            ListTile(
              leading: Icon(
                  asset.isAssigned ? Icons.person_remove : Icons.person_add),
              title: Text(asset.isAssigned ? 'Unassign Asset' : 'Assign Asset'),
              onTap: () {
                Navigator.pop(context);
                if (asset.isAssigned) {
                  _unassignAsset();
                } else {
                  _showUserSelection();
                }
              },
            ),
          if (user?.isAdmin == true && asset != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Asset',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(asset);
              },
            ),
        ],
      ),
    );
  }

  // In lib/screens/assets/asset_detail_screen.dart - Individual assignment methods

// Show user selection for individual assignment
  void _showUserSelection() async {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final asset = assetProvider.selectedAsset;

    if (asset == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserSelectionScreen(
          onUserSelected: (user) => _assignAssetToUser(user),
          currentAssignedUserId: asset.inUseBy,
        ),
      ),
    );
  }

// Individual asset assignment
  Future<void> _assignAssetToUser(User user) async {
    try {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      final asset = assetProvider.selectedAsset;

      if (asset == null) return;

      print('🎯 Assigning Asset to User:');
      print('🎯 Asset: ${asset.internalId}');
      print('🎯 User: ${user.fullName} (${user.email})');

      await assetProvider.assignAsset(
          asset.id, user.id, user.fullName, user.email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asset assigned to ${user.fullName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign asset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Individual asset unassignment
  Future<void> _unassignAsset() async {
    try {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      final asset = assetProvider.selectedAsset;

      if (asset == null) return;

      await assetProvider.unassignAsset(asset.id);

      // Force UI update
      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asset unassigned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unassign asset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text(
          'Are you sure you want to delete asset ${asset.internalId}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAsset();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to your _AssetDetailScreenState class:
  void _quickMarkAsServiced(Asset asset) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final serviceLog = ServiceLog(
      id: 0,
      assetId: asset.id,
      serviceType: 'PREVENTIVE_MAINTENANCE',
      description: 'Quick service - marked as serviced',
      serviceDate: DateTime.now(),
      performedBy: currentUser.id,
      cost: null,
      notes: 'Asset marked as serviced via quick action',
      nextServiceDate: DateTime.now().add(const Duration(days: 180)),
      // 6 months from now
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Serviced'),
        content: const Text(
            'This will create a service log entry marking this asset as serviced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final serviceLogProvider =
                    Provider.of<ServiceLogProvider>(context, listen: false);
                await serviceLogProvider.createServiceLog(
                    serviceLog, authProvider.authData!.token);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Asset marked as serviced'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Refresh the service logs
                _loadServiceLogs();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to mark as serviced: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Mark as Serviced'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAsset() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    try {
      await assetProvider.deleteAsset(
          widget.assetId, authProvider.authData!.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete asset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context);
    final asset = assetProvider.selectedAsset;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset?.internalId ?? 'Asset Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: assetProvider.isLoading ? null : _refreshAsset,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showActionMenu,
            tooltip: 'Actions',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: assetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : asset == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshAsset,
                  child: Column(
                    children: [
                      _buildPageIndicator(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          children: [
                            _buildOverviewPage(asset),
                            _buildTechnicalPage(asset),
                            _buildServicePage(asset),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageIndicatorItem('Overview', 0),
          _buildPageIndicatorItem('Technical', 1),
          _buildPageIndicatorItem('Service', 2),
        ],
      ),
    );
  }

  Widget _buildPageIndicatorItem(String title, int pageIndex) {
    final isActive = _currentPage == pageIndex;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Asset Not Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('The requested asset could not be loaded.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Assets'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage(Asset asset) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: asset.statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAssetTypeIcon(asset.assetType),
                          color: asset.statusColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.internalId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asset.manufacturer} ${asset.model}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: asset.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                asset.statusDisplay,
                                style: TextStyle(
                                  color: asset.statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAssignmentSection(asset),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(Asset asset) {
  final authProvider = Provider.of<AuthProvider>(context);
  final user = authProvider.currentUser;
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (asset.isAssigned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently assigned to:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          asset.assignedToName != null &&
                                  asset.assignedToName!.isNotEmpty
                              ? asset.assignedToName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.assignedToName ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (asset.assignedToEmail != null && asset.assignedToEmail!.isNotEmpty)
                              Text(
                                asset.assignedToEmail!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            // Show role indicator for Team Leads - we'll infer from context
                            if (user?.isStaff == true)
                              Text(
                                'Team Member', // Generic label since we don't have role data
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Show unassign button only for Admin/IT Staff
                      if (user?.isAdmin == true || user?.isITStaff == true)
                        IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.red),
                          onPressed: _unassignAsset,
                          tooltip: 'Unassign Asset',
                        ),
                    ],
                  ),
                ),
                // Additional info for Team Leads
                if (user?.isStaff == true && asset.isAssigned)
                  _buildTeamLeadAssignmentInfo(asset),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not assigned to anyone',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                // Show assign button only for Admin/IT Staff
                if (user?.isAdmin == true || user?.isITStaff == true)
                  ElevatedButton.icon(
                    onPressed: _showUserSelection,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign to User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                // Show info for Team Leads when asset is unassigned
                if (user?.isStaff == true && !asset.isAssigned)
                  _buildTeamLeadUnassignedInfo(),
              ],
            ),
        ],
      ),
    ),
  );
}

//for team lead assignment info

// Add this method for Team Lead assignment information
Widget _buildTeamLeadAssignmentInfo(Asset asset) {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info, color: Colors.green[600], size: 16),
            const SizedBox(width: 8),
            const Text(
              'Team Lead Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This asset is assigned to one of your team members.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 4),
        // You could add more team-specific info here, like:
        // - Team member's performance stats
        // - Recent tickets for this asset
        // - Upcoming maintenance
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text('Active Asset'),
              backgroundColor: Colors.green[100],
              labelStyle: const TextStyle(color: Colors.green),
            ),
            if (asset.needsService)
              Chip(
                label: Text('Needs Service'),
                backgroundColor: Colors.orange[100],
                labelStyle: const TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ],
    ),
  );
}

// Add this method for unassigned asset info for Team Leads
Widget _buildTeamLeadUnassignedInfo() {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600], size: 16),
            const SizedBox(width: 8),
            const Text(
              'Unassigned Asset',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This asset is not currently assigned to any team member. '
          'Contact IT staff to have it assigned.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.orange[800],
          ),
        ),
      ],
    ),
  );
}

// Helper method to get role name from role ID
String _getRoleName(int roleId) {
  switch (roleId) {
    case 1: return 'Admin';
    case 2: return 'IT Staff';
    case 3: return 'Team Lead';
    case 4: return 'Agent';
    case 5: return 'Viewer';
    default: return 'Unknown Role';
  }
}

// Helper method to get role color from role ID
Color _getRoleColor(int roleId) {
  switch (roleId) {
    case 1: return Colors.red; // Admin
    case 2: return Colors.orange; // IT Staff
    case 3: return Colors.green; // Team Lead
    case 4: return Colors.blue; // Agent
    case 5: return Colors.grey; // Viewer
    default: return Colors.blueGrey;
  }
}

  Widget _buildTechnicalPage(Asset asset) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                children: [
                  _buildTableRow('Internal ID', asset.internalId),
                  _buildTableRow('Asset Type', asset.assetType),
                  _buildTableRow('Manufacturer', asset.manufacturer),
                  _buildTableRow('Model', asset.model),
                  _buildTableRow('Model Number',
                      asset.modelNumber.isEmpty ? 'N/A' : asset.modelNumber),
                  _buildTableRow('Serial Number',
                      asset.serialNumber.isEmpty ? 'N/A' : asset.serialNumber),
                  _buildTableRow('Status', asset.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

//  asset service page
  Widget _buildServicePage(Asset asset) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Consumer<ServiceLogProvider>(
      builder: (context, serviceLogProvider, child) {
        // Load service logs when this page is built (if not already loading)
        if (_isInitialLoad &&
            !serviceLogProvider.isLoading &&
            serviceLogProvider.serviceLogs.isEmpty) {
          _isInitialLoad = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadServiceLogs();
          });
        }

        return Column(
          children: [
            // Quick Actions Card - Hide for Agents
            if (user?.isAdmin == true ||
                user?.isITStaff == true ||
                user?.isStaff == true)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: const Text('Log Service'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ServiceLogFormScreen(asset: asset),
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.schedule, size: 16),
                            label: const Text('Schedule Service'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ScheduleServiceScreen(asset: asset),
                                ),
                              );
                            },
                          ),
                          if (asset.needsService)
                            ActionChip(
                              avatar: const Icon(Icons.warning,
                                  size: 16, color: Colors.orange),
                              label: const Text('Mark as Serviced'),
                              backgroundColor: Colors.orange[100],
                              onPressed: () {
                                _quickMarkAsServiced(asset);
                              },
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.history, size: 16),
                            label: const Text('View Full History'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ServiceLogListScreen(asset: asset),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Service History Preview - Always show for all roles (read-only)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Recent Service History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (serviceLogProvider.serviceLogs.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ServiceLogListScreen(asset: asset),
                                ),
                              );
                            },
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (serviceLogProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (serviceLogProvider.serviceLogs.isEmpty)
                      _buildServiceEmptyState(asset, serviceLogProvider)
                    else
                      _buildServiceHistoryPreview(
                          serviceLogProvider.serviceLogs),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update the _buildServiceEmptyState method to accept asset parameter:
  Widget _buildServiceEmptyState(
      Asset asset, ServiceLogProvider serviceLogProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (serviceLogProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading service history...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Icon(
          Icons.construction,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Text(
          'No Service Records',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user?.isAgent == true
              ? 'No service history available for this asset.'
              : 'No service history found for this asset.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        // Hide "Add First Service Record" button for Agents
        if (user?.isAdmin == true ||
            user?.isITStaff == true ||
            user?.isStaff == true)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceLogFormScreen(asset: asset),
                ),
              );
            },
            child: const Text('Add First Service Record'),
          ),
      ],
    );
  }

  Widget _buildServiceHistoryPreview(List<ServiceLog> serviceLogs) {
    // Show only the 3 most recent service logs
    final recentLogs = serviceLogs.take(3).toList();

    return Column(
      children:
          recentLogs.map((log) => _buildServiceLogPreviewItem(log)).toList(),
    );
  }

  // In lib/screens/assets/asset_detail_screen.dart, find the _buildServiceLogPreviewItem method:
  Widget _buildServiceLogPreviewItem(ServiceLog serviceLog) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: serviceLog.serviceTypeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getServiceTypeIcon(serviceLog.serviceType),
              color: serviceLog.serviceTypeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceLog.serviceTypeDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serviceLog.description, // This might be the problem line
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      serviceLog.performedBy.toString(),
                      // Ensure this is string
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(serviceLog.serviceDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this helper method to the asset detail screen class
  IconData _getServiceTypeIcon(String serviceType) {
    switch (serviceType) {
      case 'PREVENTIVE_MAINTENANCE':
        return Icons.build_circle;
      case 'REPAIR':
        return Icons.handyman;
      case 'INSPECTION':
        return Icons.search;
      case 'CALIBRATION':
        return Icons.tune;
      default:
        return Icons.construction;
    }
  }

// Add this method to show snackbars for not implemented features
  void _showNotImplementedSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _loadServiceLogs() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceLogProvider =
        Provider.of<ServiceLogProvider>(context, listen: false);

    if (authProvider.authData != null) {
      serviceLogProvider.loadServiceLogsForAsset(
          widget.assetId, authProvider.authData!.token);
    }
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value),
        ),
      ],
    );
  }

  IconData _getAssetTypeIcon(String assetType) {
    switch (assetType) {
      case 'PC':
        return Icons.computer;
      case 'MONITOR':
        return Icons.monitor;
      case 'KEYBOARD':
        return Icons.keyboard;
      case 'MOUSE':
        return Icons.mouse;
      case 'HEADSET':
        return Icons.headset;
      case 'UPS':
        return Icons.power;
      default:
        return Icons.devices_other;
    }
  }
}
