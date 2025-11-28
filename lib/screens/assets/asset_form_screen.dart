// filename: lib/screens/assets/asset_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../providers/asset_provider.dart';
import '../../providers/auth_provider.dart';

class AssetFormScreen extends StatefulWidget {
  final Asset? asset;

  const AssetFormScreen({super.key, this.asset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _internalIdController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();

  String _selectedAssetType = 'PC';
  String _selectedStatus = 'IN_STORAGE';
  DateTime? _selectedPurchaseDate;
  DateTime? _selectedLastServiceDate;
  DateTime? _selectedNextServiceDate;

  bool _isLoading = false;

  // Asset types and statuses
  final List<String> _assetTypes = ['PC', 'MONITOR', 'KEYBOARD', 'MOUSE', 'HEADSET', 'UPS'];
  final List<String> _statusTypes = ['IN_STORAGE', 'IN_USE', 'REPAIR', 'RETIRED'];

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      // Pre-fill form for editing
      _internalIdController.text = widget.asset!.internalId;
      _manufacturerController.text = widget.asset!.manufacturer;
      _modelController.text = widget.asset!.model;
      _modelNumberController.text = widget.asset!.modelNumber;
      _serialNumberController.text = widget.asset!.serialNumber;
      _selectedAssetType = widget.asset!.assetType;
      _selectedStatus = widget.asset!.status;
      _selectedPurchaseDate = widget.asset!.datePurchased;
      _selectedLastServiceDate = widget.asset!.lastServiceDate;
      _selectedNextServiceDate = widget.asset!.nextServiceDate;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final assetProvider = Provider.of<AssetProvider>(context, listen: false);

      final asset = Asset(
        id: widget.asset?.id ?? 0,
        internalId: _internalIdController.text.trim(),
        assetType: _selectedAssetType,
        manufacturer: _manufacturerController.text.trim(),
        model: _modelController.text.trim(),
        modelNumber: _modelNumberController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        status: _selectedStatus,
        inUseBy: widget.asset?.inUseBy, // Keep existing assignment when editing
        datePurchased: _selectedPurchaseDate,
        lastServiceDate: _selectedLastServiceDate,
        nextServiceDate: _selectedNextServiceDate,
        createdAt: widget.asset?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignedToName: widget.asset?.assignedToName,
        assignedToEmail: widget.asset?.assignedToEmail,
      );

      if (widget.asset == null) {
        // Create new asset
        await assetProvider.createAsset(asset, authProvider.authData!.token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset created successfully')),
        );
      } else {
        // Update existing asset
        await assetProvider.updateAsset(asset, authProvider.authData!.token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset updated successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset == null ? 'Add New Asset' : 'Edit Asset'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.asset != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteAsset,
              tooltip: 'Delete Asset',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Internal ID
                      TextFormField(
                        controller: _internalIdController,
                        decoration: const InputDecoration(
                          labelText: 'Internal ID *',
                          hintText: 'DPA-PC001, AM-M001, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Internal ID is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Asset Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedAssetType,
                        decoration: const InputDecoration(
                          labelText: 'Asset Type *',
                        ),
                        items: _assetTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getAssetTypeDisplay(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAssetType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Manufacturer
                      TextFormField(
                        controller: _manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          hintText: 'Dell, HP, Lenovo, etc.',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'Model name',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model Number
                      TextFormField(
                        controller: _modelNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Model Number',
                          hintText: 'Manufacturer model number',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Serial Number
                      TextFormField(
                        controller: _serialNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number',
                          hintText: 'Serial number',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                        ),
                        items: _statusTypes.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusDisplay(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Purchase Date
                      ListTile(
                        title: const Text('Purchase Date'),
                        subtitle: Text(
                          _selectedPurchaseDate != null
                              ? '${_selectedPurchaseDate!.day}/${_selectedPurchaseDate!.month}/${_selectedPurchaseDate!.year}'
                              : 'Not set',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context, (date) {
                          setState(() => _selectedPurchaseDate = date);
                        }),
                      ),

                      // Last Service Date
                      ListTile(
                        title: const Text('Last Service Date'),
                        subtitle: Text(
                          _selectedLastServiceDate != null
                              ? '${_selectedLastServiceDate!.day}/${_selectedLastServiceDate!.month}/${_selectedLastServiceDate!.year}'
                              : 'Not set',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context, (date) {
                          setState(() => _selectedLastServiceDate = date);
                        }),
                      ),

                      // Next Service Date
                      ListTile(
                        title: const Text('Next Service Date'),
                        subtitle: Text(
                          _selectedNextServiceDate != null
                              ? '${_selectedNextServiceDate!.day}/${_selectedNextServiceDate!.month}/${_selectedNextServiceDate!.year}'
                              : 'Not set',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context, (date) {
                          setState(() => _selectedNextServiceDate = date);
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              widget.asset == null ? 'Create Asset' : 'Update Asset',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _deleteAsset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to delete this asset? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final assetProvider = Provider.of<AssetProvider>(context, listen: false);
        
        await assetProvider.deleteAsset(widget.asset!.id, authProvider.authData!.token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting asset: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAssetTypeDisplay(String type) {
    switch (type) {
      case 'PC': return 'Computer';
      case 'MONITOR': return 'Monitor';
      case 'KEYBOARD': return 'Keyboard';
      case 'MOUSE': return 'Mouse';
      case 'HEADSET': return 'Headset';
      case 'UPS': return 'UPS';
      default: return type;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'IN_STORAGE': return 'In Storage';
      case 'IN_USE': return 'In Use';
      case 'REPAIR': return 'In Repair';
      case 'RETIRED': return 'Retired';
      default: return status;
    }
  }
}