// filename: lib/screens/assets/my_assets_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import '../../models/asset.dart';
import 'asset_detail_screen.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'ALL';
  String _selectedStatus = 'ALL';
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null && !_hasLoadedInitialData) {
      try {
        await assetProvider.loadAssets(authProvider.authData!.token);
        setState(() {
          _hasLoadedInitialData = true;
        });
      } catch (e) {
        print('Error loading initial assets: $e');
        // Don't set _hasLoadedInitialData to true if loading failed
      }
    }
  }

  Future<void> _refreshAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null) {
      try {
        await assetProvider.refreshAssets(authProvider.authData!.token);
      } catch (e) {
        print('Error refreshing assets: $e');
        // Error is already stored in assetProvider.error
      }
    }
  }

  List<Asset> _getMyAssets(AssetProvider assetProvider, AuthProvider authProvider) {
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return [];

    try {
      return assetProvider.getAssetsAssignedToUser(currentUser.id);
    } catch (e) {
      print('Error getting assigned assets: $e');
      return [];
    }
  }

  List<Asset> _getFilteredAssets(List<Asset> myAssets) {
    var filteredAssets = myAssets;

    // Apply type filter
    if (_selectedType != 'ALL') {
      filteredAssets = filteredAssets.where((asset) => asset.assetType == _selectedType).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'ALL') {
      filteredAssets = filteredAssets.where((asset) => asset.status == _selectedStatus).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredAssets = filteredAssets.where((asset) {
        return asset.internalId.toLowerCase().contains(query) ||
               asset.manufacturer.toLowerCase().contains(query) ||
               asset.model.toLowerCase().contains(query) ||
               asset.modelNumber.toLowerCase().contains(query);
      }).toList();
    }

    return filteredAssets;
  }

  Widget _buildAssetItem(Asset asset) {
  final isAssigned = asset.isAssigned;
  final assignedToName = asset.assignedToName;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getAssetTypeColor(asset.assetType).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                _getAssetTypeIcon(asset.assetType),
                color: _getAssetTypeColor(asset.assetType),
              ),
            ),
            // Assignment indicator badge (green dot when assigned)
            if (isAssigned)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        asset.internalId,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${asset.manufacturer} ${asset.model}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: asset.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 8),
              // Assignment status badge (only show if assigned)
              if (isAssigned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        assignedToName ?? 'Assigned to You',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Service information
          if (asset.lastServiceDate != null)
            Text(
              'Last serviced: ${_formatDate(asset.lastServiceDate!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (asset.needsService)
            Row(
              children: [
                Icon(Icons.warning, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Needs service',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

 Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.devices_other,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Text(
          'No Assets Assigned to You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You currently don\'t have any assets assigned.\nContact your Team Lead or IT Support to get equipment assigned.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _refreshAssets,
          icon: const Icon(Icons.refresh),
          label: const Text('Check for New Assignments'),
        ),
      ],
    ),
  );
}

  Widget _buildPermissionErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have permission to view assets.\nPlease contact your administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshAssets,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your assets...'),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<Asset> myAssets) {
    final types = _getAvailableTypes(myAssets);
    final statuses = _getAvailableStatuses(myAssets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type filter
        if (types.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 8,
              children: [
                const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == 'ALL',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'ALL';
                    });
                  },
                ),
                ...types.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : 'ALL';
                      });
                    },
                  );
                }),
              ],
            ),
          ),

        // Status filter
        if (statuses.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('All'),
                selected: _selectedStatus == 'ALL',
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = 'ALL';
                  });
                },
              ),
              ...statuses.map((status) {
                return FilterChip(
                  label: Text(status),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : 'ALL';
                    });
                  },
                );
              }),
            ],
          ),
      ],
    );
  }

  List<String> _getAvailableTypes(List<Asset> assets) {
    final types = assets.map((a) => a.assetType).toSet().toList();
    types.removeWhere((type) => type.isEmpty);
    types.sort();
    return types;
  }

  List<String> _getAvailableStatuses(List<Asset> assets) {
    final statuses = assets.map((a) => a.status).toSet().toList();
    statuses.removeWhere((status) => status.isEmpty);
    statuses.sort();
    return statuses;
  }

  Color _getAssetTypeColor(String type) {
    switch (type) {
      case 'PC':
        return Colors.blue;
      case 'MONITOR':
        return Colors.green;
      case 'KEYBOARD':
        return Colors.orange;
      case 'MOUSE':
        return Colors.purple;
      case 'HEADSET':
        return Colors.red;
      case 'UPS':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getAssetTypeIcon(String type) {
    switch (type) {
      case 'PC':
        return Icons.computer;
      case 'MONITOR':
        return Icons.desktop_windows;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final myAssets = _getMyAssets(assetProvider, authProvider);
    final filteredAssets = _getFilteredAssets(myAssets);
    final hasError = assetProvider.error != null;
    final isForbidden = assetProvider.error?.contains('Forbidden') == true || 
                       assetProvider.error?.contains('403') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Assets'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: assetProvider.isLoading ? null : _refreshAssets,
            tooltip: 'Refresh My Assets',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show error banner if there's an error
          if (hasError && !assetProvider.isLoading)
            _buildErrorBanner(assetProvider.error!, isForbidden),

          // Search Bar (only show if we have data and no permission error)
          if (!isForbidden && _hasLoadedInitialData)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search my assets...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

          // Filters (only show if we have assets and no error)
          if (!isForbidden && myAssets.isNotEmpty && _hasLoadedInitialData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFilterChips(myAssets),
            ),

          const SizedBox(height: 16),

          // Summary Card (only show if we have assets and no error)
          if (!isForbidden && myAssets.isNotEmpty && _hasLoadedInitialData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Total', myAssets.length.toString(), Icons.devices),
                      _buildSummaryItem('In Use', 
                        myAssets.where((a) => a.isInUse).length.toString(), 
                        Icons.check_circle,
                        color: Colors.green
                      ),
                      _buildSummaryItem('Need Service', 
                        myAssets.where((a) => a.needsService).length.toString(), 
                        Icons.build,
                        color: Colors.orange
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Main Content Area
          Expanded(
            child: _buildMainContent(
              assetProvider, 
              authProvider, 
              myAssets, 
              filteredAssets, 
              hasError, 
              isForbidden
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    AssetProvider assetProvider,
    AuthProvider authProvider,
    List<Asset> myAssets,
    List<Asset> filteredAssets,
    bool hasError,
    bool isForbidden,
  ) {
    // Loading state
    if (assetProvider.isLoading && !_hasLoadedInitialData) {
      return _buildLoadingState();
    }

    // Permission error state
    if (isForbidden) {
      return _buildPermissionErrorState();
    }

    // Other error state
    if (hasError) {
      return _buildErrorState(assetProvider.error!);
    }

    // No assets state
    if (myAssets.isEmpty && _hasLoadedInitialData) {
      return _buildEmptyState();
    }

    // Assets list
    return RefreshIndicator(
      onRefresh: _refreshAssets,
      child: filteredAssets.isEmpty && _searchController.text.isNotEmpty
          ? _buildNoSearchResultsState()
          : ListView.builder(
              itemCount: filteredAssets.length,
              itemBuilder: (context, index) {
                final asset = filteredAssets[index];
                return _buildAssetItem(asset);
              },
            ),
    );
  }

  Widget _buildErrorBanner(String error, bool isForbidden) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: isForbidden ? Colors.orange[100] : Colors.red[100],
      child: Row(
        children: [
          Icon(
            isForbidden ? Icons.warning : Icons.error,
            color: isForbidden ? Colors.orange[800] : Colors.red[800],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isForbidden 
                ? 'Permission denied. Contact administrator.'
                : 'Error loading assets: ${error.length > 50 ? '${error.substring(0, 50)}...' : error}',
              style: TextStyle(
                color: isForbidden ? Colors.orange[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: () {
              Provider.of<AssetProvider>(context, listen: false).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Unable to Load Assets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error.contains('Forbidden') 
                ? 'You don\'t have permission to view assets. Please contact your administrator.'
                : 'There was a problem loading your assets. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshAssets,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Matching Assets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color color = Colors.blue}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
}