// filename: lib/screens/tickets/ticket_verification_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class TicketVerificationDialog extends StatefulWidget {
  final String currentVerificationStatus;
  final String currentVerificationNotes;

  const TicketVerificationDialog({
    super.key,
    required this.currentVerificationStatus,
    required this.currentVerificationNotes,
  });

  @override
  State<TicketVerificationDialog> createState() => _TicketVerificationDialogState();
}

class _TicketVerificationDialogState extends State<TicketVerificationDialog> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentVerificationStatus;
    _notesController.text = widget.currentVerificationNotes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ticket Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'not_required',
                child: Text('Not Required'),
              ),
              DropdownMenuItem(
                value: 'pending',
                child: Text('Pending Verification'),
              ),
              DropdownMenuItem(
                value: 'verified',
                child: Text('Verified - Issue Resolved'),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text('Rejected - Issue Not Resolved'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Verification Notes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add verification notes...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          if (_selectedStatus == 'rejected')
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
          if (_selectedStatus == 'verified')
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Ticket can be closed after verification',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'verification_status': _selectedStatus,
            'verification_notes': _notesController.text.trim(),
          }),
          child: const Text('Update Verification'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Add this method to your Dashboard, Ticket screens, etc.
Future<void> _refreshNotifications() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  
  if (authProvider.authData != null) {
    await notificationProvider.loadUnreadCount(authProvider.authData!.token);
  }
}

// Call this after creating a ticket, updating status, etc.
// Example in your ticket creation method:
//await _refreshNotifications(); // Add this after successful ticket creation
}