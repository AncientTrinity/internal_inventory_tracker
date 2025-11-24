// filename: lib/screens/users/user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import 'user_form_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'ALL';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _roleFilters = [
    {'value': 'ALL', 'label': 'All Users'},
    {'value': '1', 'label': 'Admin'},
    {'value': '2', 'label': 'IT Staff'},
    {'value': '3', 'label': 'Staff/Team Lead'},
    {'value': '4', 'label': 'Agent'},
    {'value': '5', 'label': 'Viewer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.authData != null) {
      setState(() => _isLoading = true);
      await userProvider.loadUsers(authProvider.authData!.token);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshUsers() async {
    await _loadUsers();
  }

  List<User> _getFilteredUsers() {
    final userProvider = Provider.of<UserProvider>(context);
    var filteredUsers = userProvider.users;

    // Apply role filter
    if (_selectedRole != 'ALL') {
      final roleId = int.parse(_selectedRole);
      filteredUsers = filteredUsers.where((user) => user.roleId == roleId).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredUsers = filteredUsers.where((user) =>
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.roleName.toLowerCase().contains(query)).toList();
    }

    // Sort by name
    filteredUsers.sort((a, b) => a.fullName.compareTo(b.fullName));

    return filteredUsers;
  }

  Widget _buildUserItem(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.roleId),
          child: Text(
            user.fullName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.roleId).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.roleName,
                style: TextStyle(
                  color: _getRoleColor(user.roleId),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(userId: user.id),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: return Colors.red; // Admin
      case 2: return Colors.blue; // IT Staff
      case 3: return Colors.green; // Staff/Team Lead
      case 4: return Colors.orange; // Agent
      case 5: return Colors.grey; // Viewer
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Users Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No users match your current filters.\nTry adjusting your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
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
        children: _roleFilters.map((filter) {
          final isSelected = _selectedRole == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedRole = selected ? filter['value']! : 'ALL';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshUsers,
            tooltip: 'Refresh',
          ),
          if (currentUser?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserFormScreen(),
                  ),
                );
              },
              tooltip: 'Create User',
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
                hintText: 'Search users...',
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

          // Role Filter Chips
          _buildFilterChips(),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshUsers,
                    child: userProvider.users.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _getFilteredUsers().length,
                            itemBuilder: (context, index) {
                              final user = _getFilteredUsers()[index];
                              return _buildUserItem(user);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}