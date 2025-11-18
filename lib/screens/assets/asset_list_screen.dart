// filename: lib/screens/assets/asset_list_screen.dart
import 'package:flutter/material.dart';
import 'package:internal_inventory_tracker/screens/assets/user_selection_screen.dart';
import 'package:provider/provider.dart';

import '../../models/asset.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../widgets/common/app_drawer.dart';
import 'asset_detail_screen.dart';
import 'asset_filter_sheet.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridview = false;
  bool _isSelectionMode = false;
  Set<int> _selectedAssetIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await assetProvider.loadAssets(authProvider.authData!.token);
    }
  }

  Future<void> _refreshAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await assetProvider.refreshAssets(authProvider.authData!.token);
    }
  }

  void _applySearchFilter(String query) {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final currentFilters = assetProvider.currentFilters;

    assetProvider.updateFilters(
      AssetFilters(
        searchQuery: query.isEmpty ? null : query,
        assetType: currentFilters.assetType,
        status: currentFilters.status,
        manufacturer: currentFilters.manufacturer,
        inUseBy: currentFilters.inUseBy,
        needsService: currentFilters.needsService,
        assignmentStatus: currentFilters.assignmentStatus,
      ),
    );
  }

  void _clearFilters() {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    assetProvider.clearFilters();
    _searchController.clear();
  }

  void _showFilterDialog() {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: AssetFilterSheet(
          currentFilters: assetProvider.currentFilters,
          onFiltersChanged: (newFilters) {
            assetProvider.updateFilters(newFilters);
          },
        ),
      ),
    );
  }

  // Selection Mode Methods
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedAssetIds.clear();
      }
    });
  }

  void _toggleAssetSelection(int assetId) {
    setState(() {
      if (_selectedAssetIds.contains(assetId)) {
        _selectedAssetIds.remove(assetId);
      } else {
        _selectedAssetIds.add(assetId);
      }

      // Exit selection mode if no assets selected
      if (_selectedAssetIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllAssets() {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    setState(() {
      _selectedAssetIds = assetProvider.filteredAssets.map((a) => a.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAssetIds.clear();
      _isSelectionMode = false;
    });
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assets'),
        content: Text(
          'Are you sure you want to delete ${_selectedAssetIds.length} assets? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedAssets();
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

  void _showBulkAssignDialog() {
    if (_selectedAssetIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Assets'),
        content: Text(
          'Assign ${_selectedAssetIds.length} selected assets to a user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showUserSelectionForBulkAssignment();
            },
            child: const Text('Select User'),
          ),
        ],
      ),
    );
  }

  void _showUserSelectionForBulkAssignment() async {
    final selectedUser = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (context) => UserSelectionScreen(
          onUserSelected: (user) => _bulkAssignAssetsToUser(user),
          currentAssignedUserId: null, // Not relevant for bulk assignment
        ),
      ),
    );
  }

  Future<void> _bulkAssignAssetsToUser(User user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);

      print(
          '🎯 Bulk Assigning ${_selectedAssetIds.length} assets to ${user.fullName}');

      await assetProvider.bulkAssignAssets(_selectedAssetIds.toList(), user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_selectedAssetIds.length} assets assigned to ${user.fullName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear selection and exit selection mode
      setState(() {
        _selectedAssetIds.clear();
        _isSelectionMode = false;
      });

      // Refresh the assets list
      if (authProvider.authData != null) {
        await assetProvider.refreshAssets(authProvider.authData!.token);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign assets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Add this method to asset_list_screen.dart if you want bulk unassign

  void _showBulkUnassignDialog() {
    if (_selectedAssetIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Assets'),
        content: Text(
          'Unassign ${_selectedAssetIds.length} selected assets?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bulkUnassignAssets();
            },
            child: const Text(
              'Unassign',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUnassignAssets() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);

      // Since we don't have a bulk unassign endpoint, unassign individually
      for (final assetId in _selectedAssetIds) {
        await assetProvider.unassignAsset(assetId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedAssetIds.length} assets unassigned'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear selection and exit selection mode
      setState(() {
        _selectedAssetIds.clear();
        _isSelectionMode = false;
      });

      // Refresh the assets list
      if (authProvider.authData != null) {
        await assetProvider.refreshAssets(authProvider.authData!.token);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unassign assets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    try {
      for (final assetId in _selectedAssetIds) {
        await assetProvider.deleteAsset(assetId, authProvider.authData!.token);
      }

      setState(() {
        _selectedAssetIds.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_selectedAssetIds.length} assets deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting assets: $e')),
      );
    }
  }

  // App Bar Builder
  PreferredSizeWidget _buildAppBar(
      AssetProvider assetProvider, AuthProvider authProvider) {
    final user = authProvider.currentUser;

    if (_isSelectionMode) {
      return AppBar(
        title: Text('${_selectedAssetIds.length} selected'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        actions: [
          if (_selectedAssetIds.length != assetProvider.filteredAssets.length)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllAssets,
              tooltip: 'Select All',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed:
                _selectedAssetIds.isNotEmpty ? _showBulkDeleteDialog : null,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed:
                _selectedAssetIds.isNotEmpty ? _showBulkAssignDialog : null,
            tooltip: 'Assign Selected',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed:
                _selectedAssetIds.isNotEmpty ? _showBulkAssignDialog : null,
            tooltip: 'Assign Selected',
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            onPressed:
                _selectedAssetIds.isNotEmpty ? _showBulkUnassignDialog : null,
            tooltip: 'Unassign Selected',
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Assets'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: Icon(_isGridview ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridview = !_isGridview;
            });
          },
          tooltip: _isGridview ? 'List View' : 'Grid View',
        ),
        if (user?.isAdmin == true || user?.isITStaff == true)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/assets/add');
            },
            tooltip: 'Add New Asset',
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: assetProvider.isLoading ? null : _refreshAssets,
          tooltip: 'Refresh',
        ),
        if (assetProvider.filteredAssets.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.check_box_outlined),
            onPressed: _toggleSelectionMode,
            tooltip: 'Select Multiple',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assetProvider = Provider.of<AssetProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(assetProvider, authProvider),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchFilterBar(assetProvider),

          // Selection Info Bar
          if (_isSelectionMode && _selectedAssetIds.isNotEmpty)
            _buildSelectionBar(),

          // Statistics Bar
          _buildStatisticsBar(assetProvider),

          // Assets List/Grid
          Expanded(
            child: _buildContent(assetProvider),
          ),
        ],
      ),
    );
  }

  // Selection Bar
  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: Theme.of(context).primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            '${_selectedAssetIds.length} assets selected',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearSelection,
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Search and Filter Bar
  Widget _buildSearchFilterBar(AssetProvider assetProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Single Search Bar with Filter Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search assets...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applySearchFilter('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterDialog,
                          tooltip: 'Filters',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: _applySearchFilter,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Active Filters Display
          if (assetProvider.currentFilters.assetType != null ||
              assetProvider.currentFilters.status != null ||
              assetProvider.currentFilters.manufacturer != null ||
              assetProvider.currentFilters.needsService == true ||
              assetProvider.currentFilters.assignmentStatus != null)
            _buildActiveFilters(assetProvider),
        ],
      ),
    );
  }

  // Active Filters
  Widget _buildActiveFilters(AssetProvider assetProvider) {
    final filters = assetProvider.currentFilters;
    final activeFilters = <String>[];

    if (filters.assetType != null)
      activeFilters.add('Type: ${filters.assetType}');
    if (filters.status != null) activeFilters.add('Status: ${filters.status}');
    if (filters.manufacturer != null)
      activeFilters.add('Manufacturer: ${filters.manufacturer}');
    if (filters.needsService == true) activeFilters.add('Needs Service');
    if (filters.assignmentStatus != null) {
      activeFilters.add(
          'Assignment: ${filters.assignmentStatus == 'assigned' ? 'Assigned' : 'Unassigned'}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: activeFilters
              .map((filter) => Chip(
                    label: Text(filter),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: _clearFilters,
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear all filters'),
        ),
      ],
    );
  }

  // Statistics Bar
  Widget _buildStatisticsBar(AssetProvider assetProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', assetProvider.totalAssets.toString()),
          _buildStatItem('In Use', assetProvider.assetsInUse.toString()),
          _buildStatItem('Available', assetProvider.assetsInStorage.toString()),
          _buildStatItem(
              'Needs Service', assetProvider.assetsNeedingService.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  // Main Content
  Widget _buildContent(AssetProvider assetProvider) {
    if (assetProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assetProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${assetProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (assetProvider.assets.isEmpty) {
      return _buildEmptyState();
    }

    if (assetProvider.filteredAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No assets match your filters'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAssets,
      child: _isGridview
          ? _buildGridView(assetProvider)
          : _buildListView(assetProvider),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No assets found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  // List View
  Widget _buildListView(AssetProvider assetProvider) {
    return ListView.builder(
      itemCount: assetProvider.filteredAssets.length,
      itemBuilder: (context, index) {
        final asset = assetProvider.filteredAssets[index];
        return _buildAssetListItem(asset, assetProvider);
      },
    );
  }

  // Grid View
  Widget _buildGridView(AssetProvider assetProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: assetProvider.filteredAssets.length,
      itemBuilder: (context, index) {
        final asset = assetProvider.filteredAssets[index];
        return _buildAssetGridItem(asset, assetProvider);
      },
    );
  }

  // Asset List Item
  Widget _buildAssetListItem(Asset asset, AssetProvider assetProvider) {
    final isSelected = _selectedAssetIds.contains(asset.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleAssetSelection(asset.id),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: asset.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAssetTypeIcon(asset.assetType),
                  color: asset.statusColor,
                  size: 30,
                ),
              ),
        title: Text(
          asset.internalId,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${asset.manufacturer} ${asset.model}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: asset.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    asset.statusDisplay,
                    style: TextStyle(
                      color: asset.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (asset.isAssigned) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.person, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (asset.needsService) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Service Due',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode ? null : const Icon(Icons.chevron_right),
        onTap: () {
          if (_isSelectionMode) {
            _toggleAssetSelection(asset.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(assetId: asset.id),
              ),
            );
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleAssetSelection(asset.id);
          }
        },
      ),
    );
  }

  // Asset Grid Item
  Widget _buildAssetGridItem(Asset asset, AssetProvider assetProvider) {
    final isSelected = _selectedAssetIds.contains(asset.id);

    return Card(
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleAssetSelection(asset.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(assetId: asset.id),
              ),
            );
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleAssetSelection(asset.id);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Checkbox or Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleAssetSelection(asset.id),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: asset.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getAssetTypeIcon(asset.assetType),
                        color: asset.statusColor,
                        size: 24,
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: asset.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      asset.statusDisplay,
                      style: TextStyle(
                        color: asset.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Asset ID
              Text(
                asset.internalId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Model
              Text(
                asset.model,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Manufacturer
              Text(
                asset.manufacturer,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Indicators
              Row(
                children: [
                  if (asset.isAssigned)
                    const Icon(Icons.person, size: 12, color: Colors.blue),
                  if (asset.needsService)
                    const Icon(Icons.warning, size: 12, color: Colors.orange),
                  const Spacer(),
                  if (!_isSelectionMode)
                    const Icon(Icons.chevron_right,
                        size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get asset type icon
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
