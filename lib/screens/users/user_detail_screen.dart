// filename: lib/screens/users/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.authData != null) {
      try {
        // Try to find user in existing list first
        final existingUser = userProvider.users.firstWhere(
          (user) => user.id == widget.userId,
          orElse: () => User(
            id: 0,
            username: '',
            fullName: '',
            email: '',
            roleId: 0,
            createdAt: DateTime.now(),
          ),
        );

        if (existingUser.id != 0) {
          setState(() {
            _user = existingUser;
          });
        } else {
          // If not found, fetch from API
          final user = await userProvider.getUserById(widget.userId, authProvider.authData!.token);
          setState(() {
            _user = user;
          });
        }
      } catch (e) {
        print('❌ Error loading user details: $e');
      }
    }
  }

  Future<void> _refreshUser() async {
    await _loadUserDetails();
  }

  void _showActionMenu() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (_user == null || currentUser == null) return;

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
              _refreshUser();
            },
          ),

          // Edit User (Admin/IT only)
          if (currentUser.isAdmin || currentUser.isITStaff)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserFormScreen(user: _user),
                  ),
                );
              },
            ),

          // Send Credentials (Admin/IT only)
          if (currentUser.isAdmin || currentUser.isITStaff)
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Credentials'),
              onTap: () {
                Navigator.pop(context);
                _sendCredentials();
              },
            ),

          // Reset Password (Admin/IT only)
          if (currentUser.isAdmin || currentUser.isITStaff)
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset Password'),
              onTap: () {
                Navigator.pop(context);
                _resetPassword();
              },
            ),

          // Delete User (Admin only)
          if (currentUser.isAdmin && _user!.id != currentUser.id) // Can't delete yourself
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteUser();
              },
            ),
        ],
      ),
    );
  }

 Future<void> _sendCredentials() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  print('🎯 SendCredentials - Starting for user: ${_user?.id}');
  print('🔐 SendCredentials - Auth token exists: ${authProvider.authData != null}');

  try {
    print('📡 SendCredentials - Calling API...');
    
    await userProvider.sendCredentials(_user!.id, authProvider.authData!.token);
    
    print('✅ SendCredentials - API call successful');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credentials sent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('❌ SendCredentials - Failed: $e');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send credentials: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _resetPassword() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show dialog to get new password from Admin/IT
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => PasswordResetDialog(),
    );

    if (newPassword != null && newPassword.isNotEmpty) {
      try {
        // Ask if they want to send email notification
        final sendEmail = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Send Email Notification?'),
            content: const Text('Do you want to send an email notification to the user about this password change?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ?? false;

        // ✅ CORRECTED: Now passing 4 parameters
        await userProvider.resetPassword(_user!.id, newPassword, sendEmail, authProvider.authData!.token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sendEmail
                ? 'Password reset successfully and user notified via email'
                : 'Password reset successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${_user!.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await userProvider.deleteUser(_user!.id, authProvider.authData!.token);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navigate back to user list
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    if (_user == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getRoleColor(_user!.roleId),
                  child: Text(
                    _user!.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _user!.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(_user!.roleId).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _user!.roleName,
                          style: TextStyle(
                            color: _getRoleColor(_user!.roleId),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.person, _user!.username),
                _buildInfoChip(Icons.calendar_today, 
                  'Joined ${DateFormat('MMM dd, yyyy').format(_user!.createdAt)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Colors.grey[100],
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: return Colors.red;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      case 5: return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildPermissionsSection() {
    if (_user == null) return const SizedBox();

    final permissions = [
      {'icon': Icons.confirmation_number, 'label': 'Create Tickets', 'value': _user!.canCreateTickets},
      {'icon': Icons.assignment_ind, 'label': 'Assign Tickets', 'value': _user!.canAssignTickets},
      {'icon': Icons.visibility, 'label': 'View All Tickets', 'value': _user!.canViewAllTickets},
      {'icon': Icons.edit, 'label': 'Edit Tickets', 'value': _user!.canEditTickets},
      {'icon': Icons.verified, 'label': 'Verify Tickets', 'value': _user!.canVerifyTickets},
      {'icon': Icons.close, 'label': 'Close Tickets', 'value': _user!.canCloseTickets},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: permissions.map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: permission['value'] as bool ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: permission['value'] as bool ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        permission['icon'] as IconData,
                        size: 16,
                        color: permission['value'] as bool ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        permission['label'] as String,
                        style: TextStyle(
                          color: permission['value'] as bool ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.fullName ?? 'User Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUser,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showActionMenu,
            tooltip: 'Actions',
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshUser,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUserHeader(),
                  const SizedBox(height: 16),
                  _buildPermissionsSection(),
                ],
              ),
            ),
    );
  }

}

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}


class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new password for this user:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: _passwordValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: _confirmPasswordValidator,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}