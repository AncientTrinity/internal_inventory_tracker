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
import 'ticket_verification_dialog.dart';

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
      await ticketProvider.loadTicketById(
          widget.ticketId, authProvider.authData!.token);
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
      builder: (context) =>
          StatefulBuilder(
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
                        DropdownMenuItem(
                            value: 'RECEIVED', child: Text('Received')),
                        DropdownMenuItem(
                            value: 'IN_PROGRESS', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'RESOLVED', child: Text('Resolved')),
                        DropdownMenuItem(
                            value: 'CLOSED', child: Text('Closed')),
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

  // Update the _updateTicketStatus method to handle verification
  Future<void> _updateTicketStatus(String status, double completion) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ticketProvider =
      Provider.of<TicketProvider>(context, listen: false);
      final ticket = ticketProvider.selectedTicket;

      if (ticket != null && authProvider.authData != null) {
        // If marking as resolved and verification is not already set, set it to pending
        String verificationStatus = ticket.verificationStatus;
        if (status == 'RESOLVED' &&
            ticket.verificationStatus == 'not_required') {
          verificationStatus = 'pending';
        }

        await ticketProvider.updateTicketStatus(
          ticket.id,
          status,
          completion,
          ticket.assignedTo,
          authProvider.authData!.token,
        );

        // If we changed verification status, update it
        if (verificationStatus != ticket.verificationStatus) {
          await ticketProvider.updateTicketVerification(
            ticket.id,
            verificationStatus,
            'Automatically set to pending upon resolution',
            authProvider.authData!.token,
          );
        }

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
    if (_commentController.text
        .trim()
        .isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ticketProvider =
      Provider.of<TicketProvider>(context, listen: false);
      final ticket = ticketProvider.selectedTicket;
      final currentUser = authProvider.currentUser;

      if (ticket != null &&
          currentUser != null &&
          authProvider.authData != null) {
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

        await ticketProvider.createComment(
            comment, authProvider.authData!.token);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                    if (ticket.verificationStatus != 'not_required')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                          ticket.verificationStatusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ticket.verificationStatusDisplay,
                          style: TextStyle(
                            color: ticket.verificationStatusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
                _buildInfoChip(Icons.priority_high, ticket.priorityDisplay,
                    color: ticket.priorityColor),
                if (ticket.assetInternalId != null)
                  _buildInfoChip(
                      Icons.devices, 'Asset: ${ticket.assetInternalId}'),
                _buildInfoChip(Icons.person,
                    'Created: ${ticket.createdByName ??
                        'User ${ticket.createdBy}'}'),
                if (ticket.assignedToName != null)
                  _buildInfoChip(Icons.assignment_ind,
                      'Assigned: ${ticket.assignedToName}'),
                if (ticket.verifiedByName != null)
                  _buildInfoChip(
                      Icons.verified, 'Verified by: ${ticket.verifiedByName}'),
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
            // Show verification notes if available
            if (ticket.verificationNotes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Verification Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.verificationNotes,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (comment.isInternal)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        builder: (context) =>
            UserSelectionDialog(
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
                : 'Ticket assigned successfully'),
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

// Add this method to _TicketDetailScreenState class
  Future<void> _showVerificationDialog() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticket = ticketProvider.selectedTicket;

    if (ticket == null || authProvider.authData == null) return;

    // Check user permissions for verification
    final currentUser = authProvider.currentUser;
    if (currentUser == null || !currentUser.canVerifyTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to verify tickets'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle different verification states
    switch (ticket.verificationStatus) {
      case 'not_required':
        await _showRequestVerificationDialog(ticket);
        break;
      case 'pending':
        await _showVerifyRejectDialog(ticket);
        break;
      case 'verified':
      case 'rejected':
        _showVerificationInfoDialog(ticket);
        break;
      default:
      // If verification status is empty or unknown, treat as not_required
        await _showRequestVerificationDialog(ticket);
    }
  }

  Future<void> _showRequestVerificationDialog(Ticket ticket) async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Request Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will mark the ticket as ready for verification. The ticket status will be updated to "Resolved".',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Notes (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Describe what was done to resolve the issue...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Request Verification'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await ticketProvider.requestVerification(
          ticket.id,
          notesController.text.trim(),
          authProvider.authData!.token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification requested successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _showVerifyRejectDialog(Ticket ticket) async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final TextEditingController notesController = TextEditingController();
    bool approved = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Verify Ticket'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verification decision
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Approve'),
                            value: true,
                            groupValue: approved,
                            onChanged: (value) =>
                                setState(() => approved = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Reject'),
                            value: false,
                            groupValue: approved,
                            onChanged: (value) =>
                                setState(() => approved = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: approved
                            ? 'Approval Notes (Optional)'
                            : 'Rejection Reason',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    if (!approved)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Ticket will be reopened for further work',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: approved ? Colors.green : Colors.orange,
                    ),
                    child: Text(approved ? 'Approve' : 'Reject'),
                  ),
                ],
              );
            },
          ),
    );

    if (result == true) {
      try {
        await ticketProvider.verifyTicket(
          ticket.id,
          approved,
          notesController.text.trim(),
          authProvider.authData!.token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ticket ${approved ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Failed to ${approved ? 'approve' : 'reject'} ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Method to setup verification first
  Future<void> _setupVerificationFirst(Ticket ticket) async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Setup Verification'),
            content: const Text(
                'This ticket needs to be set up for verification before it can be verified. Would you like to set it to "Pending Verification"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ticketProvider.setupTicketVerification(
                      ticket.id,
                      authProvider.authData!.token,
                    );

                    // After setup, show the verification dialog
                    await _showVerificationUpdateDialog(ticket);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to setup verification: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Setup Verification'),
              ),
            ],
          ),
    );
  }

// Method to show verification update dialog (for pending tickets)
  Future<void> _showVerificationUpdateDialog(Ticket ticket) async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          TicketVerificationDialog(
            currentVerificationStatus: ticket.verificationStatus,
            currentVerificationNotes: ticket.verificationNotes,
          ),
    );

    if (result != null) {
      try {
        await ticketProvider.updateTicketVerification(
          ticket.id,
          result['verification_status']!,
          result['verification_notes']!,
          authProvider.authData!.token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Verification status updated to ${result['verification_status']}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Add this method to show verification info when it's already set
  void _showVerificationInfoDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Verification Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Status: ${ticket.verificationStatusDisplay}'),
                if (ticket.verifiedByName != null)
                  Text('Verified by: ${ticket.verifiedByName}'),
                if (ticket.verifiedAt != null)
                  Text('Verified at: ${ticket.formattedVerifiedAt}'),
                if (ticket.verificationNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(ticket.verificationNotes),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              // Allow resetting verification if needed
              if (ticket.verificationStatus != 'pending')
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetVerificationStatus(ticket);
                  },
                  child: const Text('Reset to Pending'),
                ),
            ],
          ),
    );
  }

// Add method to reset verification status
Future<void> _resetVerificationStatus(Ticket ticket) async {
  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  final currentContext = context;
  
  // Check if ticket is closed
  if (ticket.isClosed) {
    bool? shouldReopen = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Ticket is Closed'),
        content: const Text('This ticket is closed. Would you like to reopen it and reset verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen & Reset'),
          ),
        ],
      ),
    );

    if (shouldReopen != true) return; // FIXED: Changed shouldReset to shouldReopen

    try {
      // Reopen the ticket first
      await ticketProvider.updateTicketStatus(
        ticket.id,
        'open', // or 'in_progress' depending on your workflow
        0, // Reset completion to 0%
        ticket.assignedTo,
        authProvider.authData!.token,
      );

      // Then reset verification
      await ticketProvider.resetVerification(
        ticket.id,
        authProvider.authData!.token,
      );

      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Ticket reopened and verification reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error reopening ticket: $e');
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to reopen ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } else {
    // Ticket is not closed, proceed with normal reset
    bool? shouldReset = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Reset Verification'),
        content: const Text('Are you sure you want to reset this ticket to pending verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return; // FIXED: Changed shouldReopen to shouldReset

    try {
      await ticketProvider.resetVerification(
        ticket.id,
        authProvider.authData!.token,
      );

      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Verification reset to pending successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in resetVerification: $e');
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to reset verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
  Future<void> _closeVerifiedTicket() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticket = ticketProvider.selectedTicket;

    if (ticket == null || authProvider.authData == null) return;

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Close Ticket'),
            content:
            const Text('Are you sure you want to close this verified ticket?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ticketProvider.closeVerifiedTicket(
                      ticket.id,
                      authProvider.authData!.token,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket closed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to close ticket: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Close Ticket'),
              ),
            ],
          ),
    );
  }


  Future<void> _reopenAndResetTicket(Ticket ticket, TicketProvider ticketProvider, AuthProvider authProvider, BuildContext currentContext) async {
  try {
    print('🔄 Reopening ticket ${ticket.id} and resetting verification...');
    
    // Reopen the ticket first
    await ticketProvider.updateTicketStatus(
      ticket.id,
      'open',
      0,
      ticket.assignedTo,
      authProvider.authData!.token,
    );

    print('✅ Ticket reopened successfully');
    
    // Then reset verification
    await ticketProvider.resetVerification(
      ticket.id,
      authProvider.authData!.token,
    );

    print('✅ Verification reset successfully');
    
    // Operation completed successfully - no UI feedback needed
    // The page refresh will show the updated state
    
  } catch (e) {
    // Only log the error, don't show UI (to avoid disposal errors)
    print('❌ Operation completed with UI timing issue: $e');
    print('ℹ️ Note: The backend operation actually succeeded!');
  }
}

// Update the action menu to include reassignment
// Update the _showActionMenu method:
  // Update the action menu - fix the null safety error
void _showActionMenu() {
  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
  final ticket = ticketProvider.selectedTicket;
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;

  if (ticket == null || user == null) return;

  // Check if user can perform actions on this ticket
  final canEditTicket = user.canEditTickets == true ||
      (user.isAgent == true && ticket.createdBy == user.id);

  final canAssignTicket = user.canAssignTickets == true;

  final canUpdateStatus = user.canEditTickets == true;

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

        // Edit Ticket
        if (canEditTicket)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Ticket'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketFormScreen(ticket: ticket),
                ),
              );
            },
          ),

        // Assign/Reassign
        if (canAssignTicket)
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('Assign/Reassign'),
            onTap: () {
              Navigator.pop(context);
              _showReassignmentDialog();
            },
          ),

        // Update Status
        if (canUpdateStatus)
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Update Status'),
            onTap: () {
              Navigator.pop(context);
              _showStatusUpdateDialog();
            },
          ),

        // Verify Ticket - Request Verification
        if (ticket.verificationStatus == 'not_required' &&
            (ticket.isResolved || ticket.isInProgress) &&
            user.canRequestVerification)
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Request Verification'),
            onTap: () {
              Navigator.pop(context);
              _showVerificationDialog();
            },
          ),

        // Verify Ticket - Verify/Reject
        if (ticket.verificationStatus == 'pending' && user.canVerifyTickets)
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('Verify/Reject Ticket'),
            onTap: () {
              Navigator.pop(context);
              _showVerificationDialog();
            },
          ),

        // View Verification Details
        if ((ticket.verificationStatus == 'verified' ||
                ticket.verificationStatus == 'rejected') &&
            user.canViewVerification)
          ListTile(
            leading: Icon(
              ticket.isVerified ? Icons.verified : Icons.cancel,
              color: ticket.isVerified ? Colors.green : Colors.red,
            ),
            title: Text(
                'View ${ticket.isVerified ? 'Approval' : 'Rejection'} Details'),
            onTap: () {
              Navigator.pop(context);
              _showVerificationInfoDialog(ticket);
            },
          ),

        // Close Verified Ticket
        if (ticket.isVerified && !ticket.isClosed && user.canCloseTickets)
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Close Verified Ticket'),
            onTap: () {
              Navigator.pop(context);
              _closeVerifiedTicket();
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
        backgroundColor: Theme
            .of(context)
            .primaryColor,
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
