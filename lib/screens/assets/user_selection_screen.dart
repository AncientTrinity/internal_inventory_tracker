// filename: lib/screens/assets/user_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class UserSelectionScreen extends StatefulWidget {
  final Function(User) onUserSelected;
  final int? currentAssignedUserId;

  const UserSelectionScreen({
    Key? key,
    required this.onUserSelected,
    this.currentAssignedUserId,
  }) : super(key: key);

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUsers();
      setState(() {
        _initialLoad = false;
        _filteredUsers = authProvider.users;
      });
    } catch (e) {
      setState(() => _initialLoad = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _filteredUsers = authProvider.users.where((user) {
        final nameMatch = user.fullName.toLowerCase().contains(query);
        final emailMatch = user.email.toLowerCase().contains(query);
        final usernameMatch = user.username.toLowerCase().contains(query);
        final roleMatch = user.roleName.toLowerCase().contains(query);
        return nameMatch || emailMatch || usernameMatch || roleMatch;
      }).toList();
    });
  }

  void _selectUser(User user) {
    widget.onUserSelected(user);
    Navigator.of(context).pop();
  }

  Widget _buildUserList() {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.loadingUsers || _initialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isCurrentlyAssigned = widget.currentAssignedUserId == user.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isCurrentlyAssigned ? Colors.blue[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.roleId),
              child: Text(
                user.fullName.isNotEmpty 
                    ? user.fullName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentlyAssigned ? Colors.blue[700] : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.roleId).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.roleName,
                        style: TextStyle(
                          color: _getRoleColor(user.roleId),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isCurrentlyAssigned
                ? Chip(
                    label: const Text(
                      'Currently Assigned',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _selectUser(user),
          ),
        );
      },
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: return Colors.red; // Admin
      case 2: return Colors.orange; // IT Staff
      case 3: return Colors.green; // Staff/Team Lead
      case 4: return Colors.blue; // Agent
      case 5: return Colors.grey; // Viewer
      default: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign to User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          // User List
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}