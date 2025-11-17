import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../widgets/app_drawer.dart';
import 'asset_form_screen.dart';

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
      await assetProvider.loadAssetById(widget.assetId, authProvider.authData!.token);
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
          // Edit action for Admin and IT
          if ((user?.isAdmin == true || user?.isITStaff == true) && asset != null)
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
          // Assignment actions
          if ((user?.isAdmin == true || user?.isITStaff == true) && asset != null)
            ListTile(
              leading: Icon(asset.isAssigned ? Icons.person_remove : Icons.person_add),
              title: Text(asset.isAssigned ? 'Unassign Asset' : 'Assign Asset'),
              onTap: () {
                Navigator.pop(context);
                _showAssignmentDialog(asset);
              },
            ),
          // Delete action for Admin only
          if (user?.isAdmin == true && asset != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Asset', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(asset);
              },
            ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(asset.isAssigned ? 'Unassign Asset' : 'Assign Asset'),
        content: Text(
          asset.isAssigned
              ? 'Are you sure you want to unassign this asset from the current user?'
              : 'Asset assignment functionality will be implemented in the next part.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (asset.isAssigned)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unassignAsset();
              },
              child: const Text('Unassign'),
            ),
        ],
      ),
    );
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

  Future<void> _unassignAsset() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    try {
      await assetProvider.unassignAsset(widget.assetId, authProvider.authData!.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset unassigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unassign asset: $e')),
        );
      }
    }
  }

  Future<void> _deleteAsset() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    try {
      await assetProvider.deleteAsset(widget.assetId, authProvider.authData!.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully')),
        );
        Navigator.pop(context); // Go back to list
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
                      // Page Indicator
                      _buildPageIndicator(),
                      
                      // Content Pages
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

  // Page Indicator
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

  // Error State
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

  // Overview Page
  Widget _buildOverviewPage(Asset asset) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Asset Icon
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
                      // Asset Info
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

          // Quick Info Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildInfoCard(
                'Asset Type',
                asset.typeDisplay,
                Icons.category,
                Colors.blue,
              ),
              _buildInfoCard(
                'Serial Number',
                asset.serialNumber.isEmpty ? 'Not set' : asset.serialNumber,
                Icons.confirmation_number,
                Colors.green,
              ),
              _buildInfoCard(
                'Model Number',
                asset.modelNumber.isEmpty ? 'Not set' : asset.modelNumber,
                Icons.model_training,
                Colors.orange,
              ),
              _buildInfoCard(
                'Purchase Date',
                asset.datePurchased != null
                    ? '${asset.datePurchased!.day}/${asset.datePurchased!.month}/${asset.datePurchased!.year}'
                    : 'Not set',
                Icons.calendar_today,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Assignment Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (asset.isAssigned) ...[
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(asset.assignedToName ?? 'Unknown User'),
                      subtitle: Text(asset.assignedToEmail ?? 'No email'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ] else ...[
                    const ListTile(
                      leading: Icon(Icons.inventory_2, color: Colors.grey),
                      title: Text('Not Assigned'),
                      subtitle: Text('This asset is available for assignment'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDateItem('Created', asset.createdAt),
                  _buildDateItem('Last Updated', asset.updatedAt),
                  if (asset.lastServiceDate != null)
                    _buildDateItem('Last Service', asset.lastServiceDate!),
                  if (asset.nextServiceDate != null)
                    _buildDateItem(
                      'Next Service',
                      asset.nextServiceDate!,
                      isWarning: asset.needsService,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Technical Page
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
                  _buildTableRow('Model Number', asset.modelNumber.isEmpty ? 'N/A' : asset.modelNumber),
                  _buildTableRow('Serial Number', asset.serialNumber.isEmpty ? 'N/A' : asset.serialNumber),
                  _buildTableRow('Status', asset.status),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Service Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceInfoItem('Last Service', asset.lastServiceDate),
                  _buildServiceInfoItem('Next Service', asset.nextServiceDate),
                  if (asset.needsService) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This asset requires service',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Service Page
  Widget _buildServicePage(Asset asset) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Placeholder for service history
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Service History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service history and maintenance records will be displayed here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Card(
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
                        avatar: const Icon(Icons.build, size: 16),
                        label: const Text('Log Service'),
                        onPressed: () {
                          // Will implement service logging
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: const Text('Schedule Service'),
                        onPressed: () {
                          // Will implement service scheduling
                        },
                      ),
                      if (asset.needsService)
                        ActionChip(
                          avatar: const Icon(Icons.warning, size: 16),
                          label: const Text('Mark as Serviced'),
                          backgroundColor: Colors.orange[100],
                          onPressed: () {
                            // Will implement mark as serviced
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateItem(String label, DateTime date, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isWarning ? Colors.orange : null,
            ),
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              color: isWarning ? Colors.orange : Colors.grey[700],
            ),
          ),
          if (isWarning) ...[
            const SizedBox(width: 8),
            Icon(Icons.warning, color: Colors.orange, size: 16),
          ],
        ],
      ),
    );
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

  Widget _buildServiceInfoItem(String label, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Not set',
            style: TextStyle(
              color: date != null ? Colors.grey[700] : Colors.grey[500],
            ),
          ),
        ],
      ),
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