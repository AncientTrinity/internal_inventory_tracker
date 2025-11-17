// filename: lib/screens/assets/asset_filter_sheet.dart
import 'package:flutter/material.dart';
import '../../models/asset.dart';

class AssetFilterSheet extends StatefulWidget {
  final AssetFilters currentFilters;
  final ValueChanged<AssetFilters> onFiltersChanged;

  const AssetFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AssetFilterSheet> createState() => _AssetFilterSheetState();
}

class _AssetFilterSheetState extends State<AssetFilterSheet> {
  late AssetFilters _filters;

  // Filter options
  final List<String> _statusOptions = ['IN_STORAGE', 'IN_USE', 'REPAIR', 'RETIRED'];
  final List<String> _typeOptions = ['PC', 'MONITOR', 'KEYBOARD', 'MOUSE', 'HEADSET', 'UPS'];
  final List<String> _manufacturerOptions = ['Dell', 'HP', 'Lenovo', 'Apple', 'Samsung', 'ViewSonic', 'Acer', 'Logitech'];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _filters = AssetFilters();
    });
    widget.onFiltersChanged(AssetFilters());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Assets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _statusOptions,
                    _filters.status,
                        (value) => setState(() {
                      _filters = _filters.copyWith(status: value);
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Asset Type Filter
                  _buildFilterSection(
                    'Asset Type',
                    _typeOptions,
                    _filters.assetType,
                        (value) => setState(() {
                      _filters = _filters.copyWith(assetType: value);
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Manufacturer Filter
                  _buildFilterSection(
                    'Manufacturer',
                    _manufacturerOptions,
                    _filters.manufacturer,
                        (value) => setState(() {
                      _filters = _filters.copyWith(manufacturer: value);
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Assignment Filter
                  _buildAssignmentFilter(),
                  const SizedBox(height: 16),

                  // Service Filter
                  _buildServiceFilter(),
                ],
              ),
            ),
          ),

          // Apply Button
          ElevatedButton(
            onPressed: _applyFilters,
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
      String title,
      List<String> options,
      String? selectedValue,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(_formatFilterLabel(option)),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Assigned'),
              selected: _filters.assignmentStatus == 'assigned',
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    assignmentStatus: selected ? 'assigned' : null,
                  );
                });
              },
            ),
            FilterChip(
              label: const Text('Unassigned'),
              selected: _filters.assignmentStatus == 'unassigned',
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    assignmentStatus: selected ? 'unassigned' : null,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        FilterChip(
          label: const Text('Needs Service'),
          selected: _filters.needsService == true,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(needsService: selected ? true : null);
            });
          },
        ),
      ],
    );
  }

  String _formatFilterLabel(String value) {
    switch (value) {
      case 'IN_STORAGE': return 'In Storage';
      case 'IN_USE': return 'In Use';
      case 'REPAIR': return 'In Repair';
      case 'RETIRED': return 'Retired';
      default: return value;
    }
  }
}