// filename: lib/screens/assets/asset_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../widgets/common/app_drawer.dart';
import 'asset_form_screen.dart';
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
          if ((user?.isAdmin == true || user?.isITStaff == true) && asset != null)
            ListTile(
              leading: Icon(asset.isAssigned ? Icons.person_remove : Icons.person_add),
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

 Future<void> _assignAssetToUser(User user) async {
  try {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final asset = assetProvider.selectedAsset;
    
    if (asset == null) return;

    print('🎯 Assigning Asset:');
    print('🎯 Asset ID: ${asset.id}');
    print('🎯 Asset Internal ID: ${asset.internalId}');
    print('🎯 User to Assign:');
    print('🎯   User ID: ${user.id}');
    print('🎯   User Name: ${user.fullName}');
    print('🎯   User Email: ${user.email}');

    await assetProvider.assignAsset(asset.id, user.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asset assigned to ${user.fullName}'),
        backgroundColor: Colors.green,
      ),
    );
    
    await _refreshAsset();
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to assign asset: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _unassignAsset() async {
    try {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      final asset = assetProvider.selectedAsset;
      
      if (asset == null) return;

      // CORRECTED: Only 1 parameter (assetId)
      await assetProvider.unassignAsset(asset.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asset unassigned successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _refreshAsset();
      
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

  Future<void> _deleteAsset() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    try {
      await assetProvider.deleteAsset(widget.assetId, authProvider.authData!.token);
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
                        asset.assignedToName != null && asset.assignedToName!.isNotEmpty
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
                  _buildTableRow('Model Number', asset.modelNumber.isEmpty ? 'N/A' : asset.modelNumber),
                  _buildTableRow('Serial Number', asset.serialNumber.isEmpty ? 'N/A' : asset.serialNumber),
                  _buildTableRow('Status', asset.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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