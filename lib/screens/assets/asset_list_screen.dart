//filename: lib/screens/assets/asset_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../widgets/common/app_drawer.dart';
import 'asset_detail_screen.dart';
import 'asset_form_screen.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridview = false;

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
      ),
    );
  }

  void _clearFilters() {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    assetProvider.clearFilters();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assetProvider = Provider.of<AssetProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // View Toggle
          IconButton(
            icon: Icon(_isGridview ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridview = !_isGridview;
              });
            },
            tooltip: _isGridview ? 'List View' : 'Grid View',
          ),
          // Add Asset Button (Admin & IT only)
          if (user?.isAdmin == true || user?.isITStaff == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssetFormScreen(),
                  ),
                );
              },
              tooltip: 'Add New Asset',
            ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: assetProvider.isLoading ? null : _refreshAssets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchFilterBar(assetProvider),
          
          // Statistics Bar
          _buildStatisticsBar(assetProvider),
          
          // Assets List/Grid
          Expanded(
            child: assetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshAssets,
                    child: assetProvider.filteredAssets.isEmpty
                        ? _buildEmptyState()
                        : _isGridview
                            ? _buildGridView(assetProvider)
                            : _buildListView(assetProvider),
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
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search assets...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applySearchFilter('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: _applySearchFilter,
          ),
          const SizedBox(height: 12),
          
          // Active Filters
          if (assetProvider.currentFilters.assetType != null ||
              assetProvider.currentFilters.status != null ||
              assetProvider.currentFilters.manufacturer != null)
            _buildActiveFilters(assetProvider),
        ],
      ),
    );
  }

  // Active Filters
  Widget _buildActiveFilters(AssetProvider assetProvider) {
    final filters = assetProvider.currentFilters;
    final activeFilters = <String>[];

    if (filters.assetType != null) activeFilters.add('Type: ${filters.assetType}');
    if (filters.status != null) activeFilters.add('Status: ${filters.status}');
    if (filters.manufacturer != null) activeFilters.add('Manufacturer: ${filters.manufacturer}');
    if (filters.needsService == true) activeFilters.add('Needs Service');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: activeFilters.map((filter) => Chip(
            label: Text(filter),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: _clearFilters,
          )).toList(),
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
          _buildStatItem('Needs Service', assetProvider.assetsNeedingService.toString()),
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
        return _buildAssetListItem(asset);
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
        return _buildAssetGridItem(asset);
      },
    );
  }

  // Asset List Item
  Widget _buildAssetListItem(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${asset.manufacturer} ${asset.model}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
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

  // Asset Grid Item
  Widget _buildAssetGridItem(Asset asset) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(assetId: asset.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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