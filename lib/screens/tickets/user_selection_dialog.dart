// filename: lib/screens/tickets/user_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class UserSelectionDialog extends StatefulWidget {
  final List<User> users;
  final String title;
  final int? currentAssigneeId;

  const UserSelectionDialog({
    super.key,
    required this.users,
    required this.title,
    this.currentAssigneeId,
  });

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.currentAssigneeId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unassign option
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.grey),
              title: const Text('Unassign'),
              trailing: _selectedUserId == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _selectedUserId = null;
                });
              },
            ),
            const Divider(),
            
            // Users list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.users.length,
                itemBuilder: (context, index) {
                  final user = widget.users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        user.fullName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.roleName} • ${user.email}'),
                    trailing: _selectedUserId == user.id
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedUserId = user.id;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedUserId),
          child: const Text('Assign'),
        ),
      ],
    );
  }

  
Future<void> _refreshNotifications() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  
  if (authProvider.authData != null) {
    await notificationProvider.loadUnreadCount(authProvider.authData!.token);
  }
}


}