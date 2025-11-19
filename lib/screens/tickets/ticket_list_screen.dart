// filename: lib/screens/tickets/ticket_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../models/asset.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asset_provider.dart';
import 'ticket_detail_screen.dart';
import 'ticket_form_screen.dart';
import 'user_selection_dialog.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String _selectedPriority = 'ALL';
  bool _showAdvancedFilters = false;
  String _selectedAssignee = 'ALL';
  String _selectedAsset = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectionMode = false;
  Set<Ticket> _selectedTickets = {};
  List<User> _availableUsers = [];
  List<Asset> _availableAssets = [];

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'ALL', 'label': 'All Tickets'},
    {'value': 'OPEN', 'label': 'Open'},
    {'value': 'RECEIVED', 'label': 'Received'},
    {'value': 'IN_PROGRESS', 'label': 'In Progress'},
    {'value': 'RESOLVED', 'label': 'Resolved'},
    {'value': 'CLOSED', 'label': 'Closed'},
  ];

  final List<Map<String, dynamic>> _priorityFilters = [
    {'value': 'ALL', 'label': 'All Priorities'},
    {'value': 'critical', 'label': 'Critical'},
    {'value': 'high', 'label': 'High'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'low', 'label': 'Low'},
  ];

@override
void initState() {
  super.initState();
  // Use Future.microtask to load after build completes
  Future.microtask(() {
    _loadTickets();
    _loadAvailableData();
  });
}

Future<void> _loadTickets() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

  if (authProvider.authData != null) {
    await ticketProvider.loadTickets(authProvider.authData!.token);
  }
}

  Future<void> _loadAvailableData() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final assetProvider = Provider.of<AssetProvider>(context, listen: false);

  if (authProvider.authData != null) {
    // Load assets for filtering
    await assetProvider.loadAssets(authProvider.authData!.token);
    setState(() {
      _availableAssets = assetProvider.assets;
    });

    // In a real app, you'd load users here for assignment
    _availableUsers = [];
  }
}

  Future<void> _refreshTickets() async {
    await _loadTickets();
  }

  List<Ticket> _getFilteredTickets() {
    final ticketProvider = Provider.of<TicketProvider>(context);
    var filteredTickets = ticketProvider.tickets;

    // Apply status filter
    if (_selectedStatus != 'ALL') {
      filteredTickets = filteredTickets.where((ticket) => ticket.status == _selectedStatus).toList();
    }

    // Apply priority filter
    if (_selectedPriority != 'ALL') {
      filteredTickets = filteredTickets.where((ticket) => ticket.priority == _selectedPriority).toList();
    }

    // Apply advanced filters
    if (_selectedAssignee != 'ALL') {
      if (_selectedAssignee == 'UNASSIGNED') {
        filteredTickets = filteredTickets.where((ticket) => ticket.assignedTo == null).toList();
      } else {
        final assigneeId = int.tryParse(_selectedAssignee);
        filteredTickets = filteredTickets.where((ticket) => ticket.assignedTo == assigneeId).toList();
      }
    }

    if (_selectedAsset != 'ALL') {
      if (_selectedAsset == 'NO_ASSET') {
        filteredTickets = filteredTickets.where((ticket) => ticket.assetId == null).toList();
      } else {
        final assetId = int.tryParse(_selectedAsset);
        filteredTickets = filteredTickets.where((ticket) => ticket.assetId == assetId).toList();
      }
    }

    // Date range filter
    if (_startDate != null) {
      filteredTickets = filteredTickets.where((ticket) => 
        ticket.createdAt.isAfter(_startDate!.subtract(const Duration(days: 1)))
      ).toList();
    }

    if (_endDate != null) {
      filteredTickets = filteredTickets.where((ticket) => 
        ticket.createdAt.isBefore(_endDate!.add(const Duration(days: 1)))
      ).toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filteredTickets = ticketProvider.searchTickets(_searchController.text);
    }

    // Sort by creation date (newest first)
    filteredTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredTickets;
  }

  Widget _buildTicketItem(Ticket ticket) {
    final isSelected = _selectedTickets.contains(ticket);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleTicketSelection(ticket),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ticket.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTicketTypeIcon(ticket.type),
                  color: ticket.statusColor,
                ),
              ),
        title: Text(
          ticket.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ticket.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.statusDisplay,
                    style: TextStyle(
                      color: ticket.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ticket.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.priorityDisplay,
                    style: TextStyle(
                      color: ticket.priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Progress indicator
                if (ticket.completion > 0)
                  Text(
                    '${ticket.completion.toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  ticket.assignedToName ?? 'Unassigned',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd').format(ticket.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode ? null : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (_isSelectionMode) {
            _toggleTicketSelection(ticket);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailScreen(ticketId: ticket.id),
              ),
            );
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleTicketSelection(ticket);
          }
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
            Icons.support_agent,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Tickets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No tickets match your current filters.\nTry adjusting your search or create a new ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicketFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Ticket'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Status filter chips
          ..._statusFilters.map((filter) {
            final isSelected = _selectedStatus == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter['label']),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? filter['value'] : 'ALL';
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedPriority,
        decoration: const InputDecoration(
          labelText: 'Priority',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: _priorityFilters.map((filter) {
          return DropdownMenuItem<String>(
            value: filter['value'],
            child: Text(filter['label']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPriority = value!;
          });
        },
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Assignee Filter
            DropdownButtonFormField<String>(
              value: _selectedAssignee,
              decoration: const InputDecoration(
                labelText: 'Assigned To',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('All Assignees')),
                const DropdownMenuItem(value: 'UNASSIGNED', child: Text('Unassigned')),
                ..._availableUsers.map((user) {
                  return DropdownMenuItem(
                    value: user.id.toString(),
                    child: Text(user.fullName),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAssignee = value!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Date Range Filter
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _startDate != null 
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : 'Start Date'
                    ),
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDate(context, isStartDate: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _endDate != null 
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : 'End Date'
                    ),
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDate(context, isStartDate: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Asset Filter
            DropdownButtonFormField<String>(
              value: _selectedAsset,
              decoration: const InputDecoration(
                labelText: 'Related Asset',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('All Assets')),
                const DropdownMenuItem(value: 'NO_ASSET', child: Text('No Asset Linked')),
                ..._availableAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset.id.toString(),
                    child: Text('${asset.internalId} - ${asset.model}'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAsset = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedFilters = false;
                      });
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    if (!_isSelectionMode || _selectedTickets.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Text(
            '${_selectedTickets.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'assign', child: Text('Assign to...')),
              const PopupMenuItem(value: 'status', child: Text('Update Status...')),
              const PopupMenuItem(value: 'priority', child: Text('Update Priority...')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Tickets')),
            ],
            onSelected: (value) => _handleBulkAction(value),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSelectionMode,
            tooltip: 'Cancel Selection',
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = 'ALL';
      _selectedPriority = 'ALL';
      _selectedAssignee = 'ALL';
      _selectedAsset = 'ALL';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTickets.clear();
      }
    });
  }

  void _toggleTicketSelection(Ticket ticket) {
    setState(() {
      if (_selectedTickets.contains(ticket)) {
        _selectedTickets.remove(ticket);
      } else {
        _selectedTickets.add(ticket);
      }
    });
  }

  Future<void> _handleBulkAction(String action) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    try {
      switch (action) {
        case 'assign':
          _showBulkAssignmentDialog();
          break;
        case 'status':
          _showBulkStatusDialog();
          break;
        case 'priority':
          _showBulkPriorityDialog();
          break;
        case 'delete':
          _showBulkDeleteDialog();
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to perform bulk action: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _showBulkAssignmentDialog() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

  if (authProvider.authData == null) return;

  try {
    // Load available users if not already loaded
    if (ticketProvider.availableUsers.isEmpty) {
      await ticketProvider.loadAvailableUsers(authProvider.authData!.token);
    }

    final selectedUserId = await showDialog<int?>(
      context: context,
      builder: (context) => UserSelectionDialog(
        users: ticketProvider.availableUsers,
        title: 'Assign ${_selectedTickets.length} Tickets',
        currentAssigneeId: null,
      ),
    );

    if (selectedUserId != null) {
      final ticketIds = _selectedTickets.map((t) => t.id).toList();
      await ticketProvider.bulkReassignTickets(
        ticketIds,
        selectedUserId,
        authProvider.authData!.token,
      );

      setState(() {
        _isSelectionMode = false;
        _selectedTickets.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedUserId == null 
            ? '${ticketIds.length} tickets unassigned successfully' 
            : '${ticketIds.length} tickets assigned successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to assign tickets: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showBulkStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('Bulk status update feature will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBulkPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Priority'),
        content: const Text('Bulk priority update feature will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tickets'),
        content: Text('Are you sure you want to delete ${_selectedTickets.length} tickets? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
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

  Future<void> _performBulkDelete() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    try {
      for (final ticket in _selectedTickets) {
        await ticketProvider.deleteTicket(ticket.id, authProvider.authData!.token);
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedTickets.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted ${_selectedTickets.length} tickets'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete tickets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getTicketTypeIcon(String type) {
    switch (type) {
      case 'activation':
        return Icons.play_arrow;
      case 'deactivation':
        return Icons.stop;
      case 'it_help':
        return Icons.help;
      case 'transition':
        return Icons.swap_horiz;
      default:
        return Icons.confirmation_number;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
            tooltip: 'Advanced Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ticketProvider.isLoading ? null : _refreshTickets,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicketFormScreen(),
                ),
              );
            },
            tooltip: 'Create Ticket',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBulkActionsBar(),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tickets...',
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
          
          // Priority Filter
          _buildPriorityFilter(),
          const SizedBox(height: 8),
          
          // Status Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 8),

          // Advanced Filters
          if (_showAdvancedFilters) _buildAdvancedFilters(),

          // Tickets List
          Expanded(
            child: ticketProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshTickets,
                    child: _getFilteredTickets().isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _getFilteredTickets().length,
                            itemBuilder: (context, index) {
                              final ticket = _getFilteredTickets()[index];
                              return _buildTicketItem(ticket);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}