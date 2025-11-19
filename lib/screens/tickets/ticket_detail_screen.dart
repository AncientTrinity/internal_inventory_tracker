// filename: lib/screens/tickets/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ticket.dart';
import '../../models/ticket_comment.dart'; // ADD THIS IMPORT
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import 'ticket_form_screen.dart';
import 'user_selection_dialog.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isInternalComment = false;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await ticketProvider.loadTicketById(widget.ticketId, authProvider.authData!.token);
    }
  }

  Future<void> _refreshTicket() async {
    await _loadTicketDetails();
  }

  void _showStatusUpdateDialog() {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final ticket = ticketProvider.selectedTicket;
    if (ticket == null) return;

    String selectedStatus = ticket.status;
    double completion = ticket.completion;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Ticket Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                    DropdownMenuItem(value: 'RECEIVED', child: Text('Received')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                      // Auto-set completion based on status
                      switch (value) {
                        case 'OPEN':
                          completion = 0;
                          break;
                        case 'RECEIVED':
                          completion = 10;
                          break;
                        case 'IN_PROGRESS':
                          completion = 50;
                          break;
                        case 'RESOLVED':
                          completion = 90;
                          break;
                        case 'CLOSED':
                          completion = 100;
                          break;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completion: ${completion.toInt()}%'),
                    Slider(
                      value: completion,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      onChanged: (value) {
                        setDialogState(() {
                          completion = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateTicketStatus(selectedStatus, completion);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateTicketStatus(String status, double completion) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final ticket = ticketProvider.selectedTicket;

      if (ticket != null && authProvider.authData != null) {
        await ticketProvider.updateTicketStatus(
          ticket.id,
          status,
          completion,
          ticket.assignedTo,
          authProvider.authData!.token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final ticket = ticketProvider.selectedTicket;
      final currentUser = authProvider.currentUser;

      if (ticket != null && currentUser != null && authProvider.authData != null) {
        final comment = TicketComment(
          id: 0,
          ticketId: ticket.id,
          userId: currentUser.id,
          comment: _commentController.text.trim(),
          isInternal: _isInternalComment,
          createdAt: DateTime.now(),
          userName: currentUser.fullName,
          userEmail: currentUser.email,
        );

        await ticketProvider.createComment(comment, authProvider.authData!.token);
        
        _commentController.clear();
        setState(() {
          _isInternalComment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTicketHeader(Ticket ticket) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ticket.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    ticket.statusDisplay,
                    style: TextStyle(
                      color: ticket.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.category, ticket.typeDisplay),
                _buildInfoChip(Icons.priority_high, ticket.priorityDisplay, color: ticket.priorityColor),
                if (ticket.assetInternalId != null)
                  _buildInfoChip(Icons.devices, 'Asset: ${ticket.assetInternalId}'),
                _buildInfoChip(Icons.person, 'Created: ${ticket.createdByName ?? 'User ${ticket.createdBy}'}'),
                if (ticket.assignedToName != null)
                  _buildInfoChip(Icons.assignment_ind, 'Assigned: ${ticket.assignedToName}'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: ticket.completion / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(ticket.statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${ticket.completion.toInt()}% Complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(text),
      backgroundColor: color?.withOpacity(0.1) ?? Colors.grey[100],
    );
  }

  Widget _buildCommentItem(TicketComment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    comment.userDisplayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        comment.formattedCreatedAt,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (comment.isInternal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Internal',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.comment),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Comment Input
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isInternalComment,
                      onChanged: (value) {
                        setState(() {
                          _isInternalComment = value ?? false;
                        });
                      },
                    ),
                    const Text('Internal'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Comments List
            if (ticketProvider.selectedTicketComments.isEmpty)
              const Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: ticketProvider.selectedTicketComments
                    .map((comment) => _buildCommentItem(comment))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReassignmentDialog() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
  final ticket = ticketProvider.selectedTicket;

  if (ticket == null || authProvider.authData == null) return;

  try {
    // Load available users if not already loaded
    if (ticketProvider.availableUsers.isEmpty) {
      await ticketProvider.loadAvailableUsers(authProvider.authData!.token);
    }

    final selectedUserId = await showDialog<int?>(
      context: context,
      builder: (context) => UserSelectionDialog(
        users: ticketProvider.availableUsers,
        title: 'Assign Ticket',
        currentAssigneeId: ticket.assignedTo,
      ),
    );

    if (selectedUserId != null) {
      await ticketProvider.reassignTicket(
        ticket.id,
        selectedUserId,
        authProvider.authData!.token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedUserId == null 
            ? 'Ticket unassigned successfully' 
            : 'Ticket assigned successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to assign ticket: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Update the action menu to include reassignment
// Update the _showActionMenu method:
  void _showActionMenu() {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final ticket = ticketProvider.selectedTicket;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Check if user can perform actions on this ticket
    final canEditTicket = user?.canEditTickets == true ||
        (user?.isAgent == true && ticket?.createdBy == user?.id);

    final canAssignTicket = user?.canAssignTickets == true;

    final canUpdateStatus = user?.canEditTickets == true;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh'),
            onTap: () {
              Navigator.pop(context);
              _refreshTicket();
            },
          ),

          // Edit Ticket - Allow creators to edit their own tickets
          if (canEditTicket == true)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Ticket'),
              onTap: () {
                Navigator.pop(context);
                if (ticket != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketFormScreen(ticket: ticket),
                    ),
                  );
                }
              },
            ),

          // Assign/Reassign - Only for Admin/IT Staff
          if (canAssignTicket == true)
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: const Text('Assign/Reassign'),
              onTap: () {
                Navigator.pop(context);
                _showReassignmentDialog();
              },
            ),

          // Update Status - Only for Admin/IT Staff
          if (canUpdateStatus == true)
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Update Status'),
              onTap: () {
                Navigator.pop(context);
                _showStatusUpdateDialog();
              },
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final ticket = ticketProvider.selectedTicket;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.title ?? 'Ticket Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ticketProvider.isLoading ? null : _refreshTicket,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showActionMenu,
            tooltip: 'Actions',
          ),
        ],
      ),
      body: ticketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshTicket,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTicketHeader(ticket),
                      const SizedBox(height: 16),
                      _buildCommentSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Ticket Not Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('The requested ticket could not be loaded.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Tickets'),
          ),
        ],
      ),
    );
  }
}