// filename: lib/screens/assets/export_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../providers/asset_provider.dart';
import '../../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedFormat = 'csv';
  String _selectedScope = 'filtered';
  bool _isExporting = false;

  final Map<String, String> _formatOptions = {
    'csv': 'CSV (Excel compatible)',
    'pdf': 'PDF Report',
  };

  final Map<String, String> _scopeOptions = {
    'all': 'All Assets',
    'filtered': 'Currently Filtered Assets',
    'selected': 'Selected Assets (if any)',
  };

  Future<void> _performExport() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);
      final List<Asset> assetsToExport;
      final String fileName;

      switch (_selectedScope) {
        case 'all':
          assetsToExport = assetProvider.assets;
          fileName = 'all_assets';
          break;
        case 'filtered':
          assetsToExport = assetProvider.filteredAssets;
          fileName = 'filtered_assets';
          break;
        case 'selected':
          // This would need selection state - for now use filtered
          assetsToExport = assetProvider.filteredAssets;
          fileName = 'selected_assets';
          break;
        default:
          assetsToExport = assetProvider.filteredAssets;
          fileName = 'assets';
      }

      if (assetsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assets to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await ExportService.exportFilteredAssets(
        allAssets: assetsToExport,
        filters: assetProvider.currentFilters,
        format: _selectedFormat,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${assetsToExport.length} assets exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildFormatSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._formatOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedFormat,
                onChanged: _isExporting ? null : (value) {
                  setState(() => _selectedFormat = value!);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Scope',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._scopeOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedScope,
                onChanged: _isExporting ? null : (value) {
                  setState(() => _selectedScope = value!);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final assetProvider = Provider.of<AssetProvider>(context);
    final int totalCount;
    final String scopeName;

    switch (_selectedScope) {
      case 'all':
        totalCount = assetProvider.assets.length;
        scopeName = 'All Assets';
        break;
      case 'filtered':
        totalCount = assetProvider.filteredAssets.length;
        scopeName = 'Filtered Assets';
        break;
      case 'selected':
        totalCount = assetProvider.filteredAssets.length; // Placeholder
        scopeName = 'Selected Assets';
        break;
      default:
        totalCount = assetProvider.filteredAssets.length;
        scopeName = 'Assets';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.blue),
              title: Text(scopeName),
              subtitle: Text('$totalCount assets will be exported'),
            ),
            if (assetProvider.currentFilters.assetType != null)
              ListTile(
                leading: const Icon(Icons.category, color: Colors.green),
                title: const Text('Asset Type Filter'),
                subtitle: Text(assetProvider.currentFilters.assetType!),
              ),
            if (assetProvider.currentFilters.status != null)
              ListTile(
                leading: const Icon(Icons.work, color: Colors.orange),
                title: const Text('Status Filter'),
                subtitle: Text(assetProvider.currentFilters.status!),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Assets'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: _isExporting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Statistics
                  _buildStatistics(),
                  const SizedBox(height: 16),
                  
                  // Format Selector
                  _buildFormatSelector(),
                  const SizedBox(height: 16),
                  
                  // Scope Selector
                  _buildScopeSelector(),
                  const SizedBox(height: 24),
                  
                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performExport,
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Export Assets',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• CSV files can be opened in Excel or Google Sheets\n'
                          '• PDF files are better for printing and sharing\n'
                          '• Apply filters first to export specific asset groups',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
}