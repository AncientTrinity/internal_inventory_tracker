// filename: lib/screens/assets/service_log_form_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show post;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/service_log.dart';
import '../../models/asset.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_config.dart';

class ServiceLogFormScreen extends StatefulWidget {
  final Asset asset;
  final ServiceLog? existingServiceLog;

  const ServiceLogFormScreen({
    super.key,
    required this.asset,
    this.existingServiceLog,
  });

  @override
  State<ServiceLogFormScreen> createState() => _ServiceLogFormScreenState();
}

class _ServiceLogFormScreenState extends State<ServiceLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // Form controllers
  late String _serviceType;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  late DateTime _serviceDate;
  late DateTime? _nextServiceDate; // NEW FIELD

  // Service type options
  final List<Map<String, dynamic>> _serviceTypes = [
    {'value': 'PREVENTIVE_MAINTENANCE', 'label': 'Preventive Maintenance'},
    {'value': 'REPAIR', 'label': 'Repair'},
    {'value': 'INSPECTION', 'label': 'Inspection'},
    {'value': 'CALIBRATION', 'label': 'Calibration'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data or defaults
    _serviceType = widget.existingServiceLog?.serviceType ?? 'PREVENTIVE_MAINTENANCE';
    _descriptionController = TextEditingController(
      text: widget.existingServiceLog?.description ?? ''
    );
    _costController = TextEditingController(
      text: widget.existingServiceLog?.cost?.toString() ?? ''
    );
    _notesController = TextEditingController(
      text: widget.existingServiceLog?.notes ?? ''
    );
    _serviceDate = widget.existingServiceLog?.serviceDate ?? DateTime.now();
    _nextServiceDate = widget.existingServiceLog?.nextServiceDate; // NEW FIELD
    
    // Auto-set next service date for preventive maintenance
    if (_serviceType == 'PREVENTIVE_MAINTENANCE' && _nextServiceDate == null) {
      _nextServiceDate = DateTime.now().add(const Duration(days: 180)); // 6 months default
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {bool isNextService = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isNextService ? _nextServiceDate ?? DateTime.now().add(const Duration(days: 180)) : _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isNextService) {
          _nextServiceDate = picked;
        } else {
          _serviceDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final serviceLogProvider = Provider.of<ServiceLogProvider>(context, listen: false);
      
      // Get current user ID
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final serviceLog = ServiceLog(
        id: widget.existingServiceLog?.id ?? 0,
        assetId: widget.asset.id,
        serviceType: _serviceType,
        description: _descriptionController.text.trim(),
        serviceDate: _serviceDate,
        performedBy: currentUser.id,
        cost: _costController.text.isNotEmpty ? double.tryParse(_costController.text) : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        nextServiceDate: _nextServiceDate, // NEW FIELD
        createdAt: widget.existingServiceLog?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📤 Sending Service Log: ${serviceLog.toJson()}');

      if (widget.existingServiceLog == null) {
        // Create new service log
        await serviceLogProvider.createServiceLog(
          serviceLog, 
          authProvider.authData!.token
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service log created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing service log
        await serviceLogProvider.updateServiceLog(
          serviceLog,
          authProvider.authData!.token
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service log updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      print('❌ Error creating service log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save service log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ServiceLog> createServiceLog(ServiceLog serviceLog, String token) async {
  try {
    print('📡 Creating service log for asset ${serviceLog.assetId}');
    print('📤 Request Body: ${serviceLog.toJson()}');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/assets/${serviceLog.assetId}/service-logs'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode(serviceLog.toJson()),
    );

    print('🔍 Response Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      print('🔍 Decoded Response: $responseData');
      print('🔍 Response Type: ${responseData.runtimeType}');
      
      // Ensure we have a Map<String, dynamic>
      if (responseData is Map) {
        final serviceLogData = Map<String, dynamic>.from(responseData);
        print('🔍 Converting to ServiceLog...');
        return ServiceLog.fromJson(serviceLogData);
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } else {
      throw Exception('Failed to create service log: ${response.statusCode} ${response.body}');
    }
  } catch (e, stackTrace) {
    print('❌ Failed to create service log: $e');
    print('❌ Stack trace: $stackTrace');
    throw Exception('Failed to create service log: $e');
  }
}

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _costValidator(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final cost = double.tryParse(value);
      if (cost == null) {
        return 'Please enter a valid number';
      }
      if (cost < 0) {
        return 'Cost cannot be negative';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingServiceLog != null;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Service Log' : 'Add Service Log',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Asset Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.devices, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.asset.internalId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${widget.asset.manufacturer} ${widget.asset.model}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current User Info
              if (currentUser != null) 
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Performed By',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                currentUser.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currentUser.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Service Type
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type *',
                  border: OutlineInputBorder(),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _serviceType = value!;
                    // Auto-set next service date for preventive maintenance
                    if (_serviceType == 'PREVENTIVE_MAINTENANCE' && _nextServiceDate == null) {
                      _nextServiceDate = DateTime.now().add(const Duration(days: 180));
                    } else if (_serviceType != 'PREVENTIVE_MAINTENANCE') {
                      _nextServiceDate = null;
                    }
                  });
                },
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Service Date
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _dateFormat.format(_serviceDate)
                ),
                decoration: const InputDecoration(
                  labelText: 'Service Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context, isNextService: false),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Next Service Date (only for preventive maintenance)
              if (_serviceType == 'PREVENTIVE_MAINTENANCE') ...[
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _nextServiceDate != null ? _dateFormat.format(_nextServiceDate!) : 'Select date'
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Next Service Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: 'Recommended for preventive maintenance',
                  ),
                  onTap: () => _selectDate(context, isNextService: true),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the service performed...',
                ),
                maxLines: 3,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: _costValidator,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Additional notes or observations...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Update Service Log' : 'Create Service Log',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}