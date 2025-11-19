// filename: lib/screens/tickets/ticket_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../models/asset.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';

class TicketTemplate {
  final String name;
  final String title;
  final String description;
  final String type;
  final String priority;
  final bool isInternal;

  TicketTemplate({
    required this.name,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.isInternal,
  });
}

class TicketFormScreen extends StatefulWidget {
  final Ticket? ticket;

  const TicketFormScreen({super.key, this.ticket});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _type;
  late String _priority;
  late int? _assetId;
  late bool _isInternal;

  // Ticket templates
  final List<TicketTemplate> _ticketTemplates = [
    TicketTemplate(
      name: 'PC Performance Issue',
      title: 'PC Performance Issue - Slow Operation',
      description: 'Computer is running slowly, applications take long to load, system freezes frequently.',
      type: 'it_help',
      priority: 'high',
      isInternal: false,
    ),
    TicketTemplate(
      name: 'Software Installation',
      title: 'Software Installation Request',
      description: 'Request to install new software for work purposes. Please specify software name and version.',
      type: 'it_help',
      priority: 'normal',
      isInternal: false,
    ),
    TicketTemplate(
      name: 'Hardware Replacement',
      title: 'Hardware Replacement Needed',
      description: 'Hardware component needs replacement. Please specify which component and symptoms.',
      type: 'it_help',
      priority: 'high',
      isInternal: false,
    ),
    TicketTemplate(
      name: 'Network Connectivity',
      title: 'Network Connectivity Issues',
      description: 'Experiencing network connectivity problems, slow internet, or connection drops.',
      type: 'it_help',
      priority: 'critical',
      isInternal: false,
    ),
    TicketTemplate(
      name: 'Email Configuration',
      title: 'Email Configuration Issue',
      description: 'Problems with email setup, sending/receiving emails, or email client configuration.',
      type: 'it_help',
      priority: 'normal',
      isInternal: false,
    ),
  ];

  // Options
  final List<Map<String, dynamic>> _ticketTypes = [
    {'value': 'it_help', 'label': 'IT Help'},
    {'value': 'activation', 'label': 'Activation'},
    {'value': 'deactivation', 'label': 'Deactivation'},
    {'value': 'transition', 'label': 'Transition'},
  ];

  final List<Map<String, dynamic>> _priorityLevels = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'high', 'label': 'High'},
    {'value': 'critical', 'label': 'Critical'},
  ];

  List<Asset> _availableAssets = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data or defaults
    _titleController = TextEditingController(text: widget.ticket?.title ?? '');
    _descriptionController = TextEditingController(text: widget.ticket?.description ?? '');
    _type = widget.ticket?.type ?? 'it_help';
    _priority = widget.ticket?.priority ?? 'normal';
    _assetId = widget.ticket?.assetId;
    _isInternal = widget.ticket?.isInternal ?? false;

    _loadAvailableAssets();
  }

  Future<void> _loadAvailableAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await assetProvider.loadAssets(authProvider.authData!.token);
      setState(() {
        _availableAssets = assetProvider.assets;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final ticket = Ticket(
        id: widget.ticket?.id ?? 0,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: widget.ticket?.status ?? 'OPEN',
        type: _type,
        priority: _priority,
        createdBy: currentUser.id,
        assignedTo: widget.ticket?.assignedTo,
        assetId: _assetId,
        completion: widget.ticket?.completion ?? 0.0,
        isInternal: _isInternal,
        createdAt: widget.ticket?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.ticket == null) {
        // Create new ticket
        await ticketProvider.createTicket(ticket, authProvider.authData!.token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing ticket
        await ticketProvider.updateTicket(ticket, authProvider.authData!.token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyTemplate(TicketTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _type = template.type;
      _priority = template.priority;
      _isInternal = template.isInternal;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied template: ${template.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Templates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a template to quickly create common ticket types',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ticketTemplates.map((template) {
                return ActionChip(
                  label: Text(template.name),
                  onPressed: () {
                    _applyTemplate(template);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ticket != null;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Ticket' : 'Create Ticket'),
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
              // Template Section
              if (!isEditing) _buildTemplateSection(),
              if (!isEditing) const SizedBox(height: 16),

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
                                'Created By',
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

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'Brief description of the issue...',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'Detailed description of the issue...',
                ),
                maxLines: 5,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Ticket Type
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Ticket Type *',
                  border: OutlineInputBorder(),
                ),
                items: _ticketTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority *',
                  border: OutlineInputBorder(),
                ),
                items: _priorityLevels.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority['value'],
                    child: Text(priority['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Asset Selection
              DropdownButtonFormField<int?>(
                value: _assetId,
                decoration: const InputDecoration(
                  labelText: 'Related Asset (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('No asset linked'),
                  ),
                  ..._availableAssets.map((asset) {
                    return DropdownMenuItem<int?>(
                      value: asset.id,
                      child: Text('${asset.internalId} - ${asset.manufacturer} ${asset.model}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _assetId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Internal Ticket
              CheckboxListTile(
                title: const Text('Internal Ticket'),
                subtitle: const Text('Only visible to IT staff and administrators'),
                value: _isInternal,
                onChanged: (value) {
                  setState(() {
                    _isInternal = value ?? false;
                  });
                },
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
                  isEditing ? 'Update Ticket' : 'Create Ticket',
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