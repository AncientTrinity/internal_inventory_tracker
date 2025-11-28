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
  }

  void _resetAndApply() {
    _clearFilters();
    widget.onFiltersChanged(AssetFilters());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _filters.assetType != null ||
        _filters.status != null ||
        _filters.manufacturer != null ||
        _filters.needsService == true ||
        _filters.assignmentStatus != null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Active Filters Count
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getActiveFilterCount()} active filters',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    Icons.work_outline,
                    _statusOptions,
                    _filters.status,
                    (value) => setState(() {
                      _filters = _filters.copyWith(status: value);
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Asset Type Filter
                  _buildFilterSection(
                    'Asset Type',
                    Icons.category_outlined,
                    _typeOptions,
                    _filters.assetType,
                    (value) => setState(() {
                      _filters = _filters.copyWith(assetType: value);
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Manufacturer Filter
                  _buildFilterSection(
                    'Manufacturer',
                    Icons.business_outlined,
                    _manufacturerOptions,
                    _filters.manufacturer,
                    (value) => setState(() {
                      _filters = _filters.copyWith(manufacturer: value);
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Assignment Filter
                  _buildAssignmentFilter(),
                  const SizedBox(height: 24),

                  // Service Filter
                  _buildServiceFilter(),
                ],
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetAndApply,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(
                _formatFilterLabel(option),
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: Theme.of(context).primaryColor,
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
        const Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Assignment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildAssignmentChip('Assigned', 'assigned'),
            _buildAssignmentChip('Unassigned', 'unassigned'),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentChip(String label, String value) {
    final isSelected = _filters.assignmentStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filters = _filters.copyWith(
            assignmentStatus: selected ? value : null,
          );
        });
      },
      selectedColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildServiceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.build_outlined, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Service Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilterChip(
          label: const Text('Needs Service'),
          selected: _filters.needsService == true,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(needsService: selected ? true : null);
            });
          },
          selectedColor: Colors.orange,
          checkmarkColor: Colors.white,
        ),
      ],
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filters.assetType != null) count++;
    if (_filters.status != null) count++;
    if (_filters.manufacturer != null) count++;
    if (_filters.needsService == true) count++;
    if (_filters.assignmentStatus != null) count++;
    return count;
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