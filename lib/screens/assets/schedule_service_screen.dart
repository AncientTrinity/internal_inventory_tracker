// filename: lib/screens/assets/schedule_service_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/service_log.dart';
import '../../models/asset.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/auth_provider.dart';

class ScheduleServiceScreen extends StatefulWidget {
  final Asset asset;

  const ScheduleServiceScreen({super.key, required this.asset});

  @override
  State<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends State<ScheduleServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // Form controllers
  late String _serviceType;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late DateTime _scheduledDate;
  late DateTime? _nextServiceDate;

  // Service type options
  final List<Map<String, dynamic>> _serviceTypes = [
    {'value': 'PREVENTIVE_MAINTENANCE', 'label': 'Preventive Maintenance'},
    {'value': 'INSPECTION', 'label': 'Inspection'},
    {'value': 'CALIBRATION', 'label': 'Calibration'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with defaults for scheduling
    _serviceType = 'PREVENTIVE_MAINTENANCE';
    _descriptionController = TextEditingController(
      text: 'Scheduled ${DateFormat('MMM dd, yyyy').format(DateTime.now().add(const Duration(days: 30)))}'
    );
    _notesController = TextEditingController();
    _scheduledDate = DateTime.now().add(const Duration(days: 30)); // Default: 30 days from now
    _nextServiceDate = DateTime.now().add(const Duration(days: 180)); // Default: 6 months from now
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {bool isNextService = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isNextService ? _nextServiceDate ?? DateTime.now().add(const Duration(days: 180)) : _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isNextService) {
          _nextServiceDate = picked;
        } else {
          _scheduledDate = picked;
          // Auto-update description if it's the default
          if (_descriptionController.text.startsWith('Scheduled')) {
            _descriptionController.text = 'Scheduled ${DateFormat('MMM dd, yyyy').format(picked)}';
          }
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
        id: 0, // Will be assigned by backend
        assetId: widget.asset.id,
        serviceType: _serviceType,
        description: _descriptionController.text.trim(),
        serviceDate: _scheduledDate,
        performedBy: currentUser.id,
        cost: null, // No cost for scheduled service
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        nextServiceDate: _nextServiceDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📤 Scheduling Service: ${serviceLog.toJson()}');

      await serviceLogProvider.createServiceLog(
        serviceLog, 
        authProvider.authData!.token
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service scheduled for ${DateFormat('MMM dd, yyyy').format(_scheduledDate)}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
      }

    } catch (e) {
      print('❌ Error scheduling service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Service'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
            tooltip: 'Schedule Service',
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
                                'Scheduled By',
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
                  });
                },
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Scheduled Date
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _dateFormat.format(_scheduledDate)
                ),
                decoration: const InputDecoration(
                  labelText: 'Scheduled Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  hintText: 'When should this service be performed?',
                ),
                onTap: () => _selectDate(context, isNextService: false),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Next Service Date (for preventive maintenance)
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
                    hintText: 'When is the next service due?',
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
                  hintText: 'Describe what service needs to be performed...',
                ),
                maxLines: 3,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Any special instructions or requirements...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Info Card about Scheduled Services
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scheduled services will appear in the service history and can help track upcoming maintenance needs.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Schedule Service',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}