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

        // 🔐 RESET PASSWORD (Set specific password + optional email)
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Reset Password'),
          subtitle: const Text('Set new password & optionally email user'),
          onTap: () {
            Navigator.pop(context);
            _resetPassword();
          },
        ),

        // 📧 SEND CURRENT CREDENTIALS (Username only + instructions)
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Send Current Credentials'),
          subtitle: const Text('Email username & password reset instructions'),
          onTap: () {
            Navigator.pop(context);
            _sendCurrentCredentials();
          },
        ),

        // ... other actions ...
      ],
    ),
  );
}

// Send current credentials (username + instructions)
Future<void> _sendCurrentCredentials() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Send Current Credentials?'),
      content: const Text('This will email the user their current username and instructions for password reset if needed. Their password will NOT be changed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await userProvider.sendCredentials(_user!.id, authProvider.authData!.token);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Current credentials sent via email'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send credentials: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Send Credentials'),
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
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => PasswordResetWithEmailDialog(),
  );

  if (result != null && result['password'] != null) {
    final newPassword = result['password'] as String;
    final sendEmail = result['sendEmail'] as bool;

    try {
      // ✅ Now resetPassword accepts both password and sendEmail flag
      await userProvider.resetPassword(_user!.id, newPassword, sendEmail, authProvider.authData!.token);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sendEmail 
            ? 'Password reset to "$newPassword" and user notified via email'
            : 'Password reset to "$newPassword" successfully'
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

  class PasswordResetWithEmailDialog extends StatefulWidget {
  const PasswordResetWithEmailDialog({super.key});

  @override
  State<PasswordResetWithEmailDialog> createState() => _PasswordResetWithEmailDialogState();
}


class _PasswordResetWithEmailDialogState extends State<PasswordResetWithEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _sendEmail = true;

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
            const Text('Set a new password for this user:'),
            const SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                hintText: 'Enter the specific password...',
              ),
              obscureText: true,
              validator: _passwordValidator,
            ),
            const SizedBox(height: 12),
            
            // Confirm password
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: _confirmPasswordValidator,
            ),
            const SizedBox(height: 16),
            
            // Email option
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text('Send email notification'),
                      subtitle: const Text('User will receive an email with the new password'),
                      value: _sendEmail,
                      onChanged: (value) {
                        setState(() {
                          _sendEmail = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_sendEmail)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Email will include: "Your new password is: [password]"',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
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
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'password': _passwordController.text,
                'sendEmail': _sendEmail,
              });
            }
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}