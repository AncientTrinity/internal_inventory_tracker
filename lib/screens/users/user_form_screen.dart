// filename: lib/screens/users/user_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  int _selectedRoleId = 3; // Default to Staff/Team Lead
  bool _isActive = true;
  bool _sendCredentials = false;

  // Role options
  final List<Map<String, dynamic>> _roleOptions = [
    {'id': 1, 'name': 'Admin', 'description': 'Full system access'},
    {'id': 2, 'name': 'IT Staff', 'description': 'Asset & ticket management'},
    {'id': 3, 'name': 'Staff/Team Lead', 'description': 'Ticket creation & verification'},
    {'id': 4, 'name': 'Agent', 'description': 'View own tickets & assets'},
    {'id': 5, 'name': 'Viewer', 'description': 'Read-only access'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if editing
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _fullNameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _selectedRoleId = widget.user!.roleId;
      // Don't pre-fill password for security
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    // For new users - password is REQUIRED when manually set by Admin/IT
    if (widget.user == null && (value == null || value.trim().isEmpty)) {
      return 'Password is required for new users';
    }
    
    // For existing users - optional, but if provided, must meet requirements
    if (value != null && value.isNotEmpty && value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

// In user_form_screen.dart - UPDATE the submit logic
// In user_form_screen.dart - UPDATE the submit logic
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Track if we're changing password and store the plaintext password
    bool isPasswordChange = widget.user != null && _passwordController.text.isNotEmpty;
    String? plaintextPassword = isPasswordChange ? _passwordController.text : null;

    // Prepare user data
    final userData = {
      'username': _usernameController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'role_id': _selectedRoleId,
    };

    // ✅ FOR NEW USERS: Password is REQUIRED
    if (widget.user == null) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password is required for new users'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      userData['password'] = _passwordController.text;
      userData['send_email'] = _sendCredentials;
    } 
    // ✅ FOR EXISTING USERS: Password is optional
    else if (_passwordController.text.isNotEmpty) {
      userData['password'] = _passwordController.text;
    }

    if (widget.user == null) {
      // Create new user
      await userProvider.createUser(userData, authProvider.authData!.token);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Update existing user
      await userProvider.updateUser(
        widget.user!.id, 
        userData, 
        authProvider.authData!.token
      );
      
      // ✅ NEW: If password was changed, send email with ACTUAL password
      if (isPasswordChange && plaintextPassword != null) {
        final shouldSendEmail = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Send Password Update Email?'),
            content: const Text('Do you want to send an email to the user with their new password?'),
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

        if (shouldSendEmail) {
          // Use a new method that sends the actual password, not a generated one
          await _sendPasswordChangeEmail(plaintextPassword);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldSendEmail 
              ? 'User updated and password change email sent successfully'
              : 'User updated successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    // Navigate back
    if (mounted) {
      Navigator.pop(context);
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to save user: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ✅ NEW METHOD: Send email with the actual password that was set
Future<void> _sendPasswordChangeEmail(String actualPassword) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  try {
    // We need to call a new endpoint that accepts the actual password
    await userProvider.sendPasswordChangeEmail(
      widget.user!.id, 
      actualPassword, 
      authProvider.authData!.token
    );
  } catch (e) {
    print('❌ Failed to send password change email: $e');
    // Don't show error - the update was still successful
  }
}

  Widget _buildRoleInfo() {
    final selectedRole = _roleOptions.firstWhere(
      (role) => role['id'] == _selectedRoleId,
      orElse: () => _roleOptions[2],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: ${selectedRole['name']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedRole['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSecurityNotice() {
    if (widget.user == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            Icon(Icons.security, color: Colors.blue[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin/IT Password Setting',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You are setting the initial password for this user. They will use this to log in.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_passwordController.text.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          children: [
            Icon(Icons.security, color: Colors.orange[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Change Security Notice',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User will be notified via email about this password change for security purposes.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _handlePasswordChangeEmail() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  try {
    // Use the send-credentials endpoint to notify user of password change
    await userProvider.sendCredentials(widget.user!.id, authProvider.authData!.token);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed and user notified via email'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('❌ Failed to send password change email: $e');
    // Don't show error to user - the update was still successful
  }
}

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Create User'),
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
              // Current User Info (for context)
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

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter unique username...',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter full name...',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter email address...',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),

              // Password (REQUIRED for new users, optional for editing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: isEditing 
                        ? 'New Password (leave blank to keep current)' 
                        : 'Password * (Set by Admin/IT)',
                      border: const OutlineInputBorder(),
                      hintText: isEditing 
                        ? 'Enter new password...' 
                        : 'Enter password for new user...',
                    ),
                    obscureText: true,
                    validator: _passwordValidator,
                    onChanged: (value) {
                      setState(() {
                        // Trigger rebuild to show/hide security notices
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Security notices
                  _buildPasswordSecurityNotice(),
                ],
              ),
              const SizedBox(height: 16),

              // Role Selection
              DropdownButtonFormField<int>(
                value: _selectedRoleId,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                ),
                items: _roleOptions.map((role) {
                  return DropdownMenuItem<int>(
                    value: role['id'],
                    child: Text(role['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoleId = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Role Information
              _buildRoleInfo(),
              const SizedBox(height: 16),

              // Active Status
              CheckboxListTile(
                title: const Text('Active User'),
                subtitle: const Text('User can login and use the system'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
              ),

              // Send Credentials (for new users only)
              if (!isEditing)
                CheckboxListTile(
                  title: const Text('Send Welcome Email'),
                  subtitle: const Text('Send credentials to user via email'),
                  value: _sendCredentials,
                  onChanged: (value) {
                    setState(() {
                      _sendCredentials = value ?? false;
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
                  isEditing ? 'Update User' : 'Create User',
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