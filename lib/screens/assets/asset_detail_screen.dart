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

  @override
  void initState() {
    super.initState();
    _loadAssetDetails();
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

    await assetProvider.assignAsset(asset.id, user.id, user.fullName, user.email);
    
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
      nextServiceDate: DateTime.now().add(const Duration(days: 180)), // 6 months from now
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Serviced'),
        content: const Text('This will create a service log entry marking this asset as serviced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final serviceLogProvider = Provider.of<ServiceLogProvider>(context, listen: false);
                await serviceLogProvider.createServiceLog(
                    serviceLog,
                    authProvider.authData!.token
                );

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
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        asset.assignedToName != null &&
                                asset.assignedToName!.isNotEmpty
                            ? asset.assignedToName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      asset.assignedToName ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(asset.assignedToEmail ?? 'No email'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: _unassignAsset,
                      tooltip: 'Unassign Asset',
                    ),
                  ),
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
                  ElevatedButton.icon(
                    onPressed: _showUserSelection,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign to User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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
    return Consumer<ServiceLogProvider>(
      builder: (context, serviceLogProvider, child) {
        return Column(
          children: [
            // Quick Actions Card
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

            // Service History Preview
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
                      _buildServiceEmptyState()
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

  Widget _buildServiceEmptyState() {
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
        const Text(
          'No service history found for this asset.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            _showNotImplementedSnackbar(
                'Service log creation will be implemented next');
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
