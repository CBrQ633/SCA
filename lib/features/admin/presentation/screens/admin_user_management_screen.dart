import 'package:flutter/material.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/data/user_model.dart';
import 'package:intl/intl.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AuthRepository _authRepo = AuthRepository();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authRepo.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _updateUserRole(UserModel user, String newRole) async {
    try {
      await _authRepo.updateUser(user.id, {'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User role updated to ${newRole.toUpperCase()}')),
        );
      }
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleSubscription(UserModel user) async {
    final newStatus =
        user.subscriptionStatus == 'active' ? 'inactive' : 'active';
    try {
      final now = DateTime.now();
      await _authRepo.updateUser(user.id, {
        'subscription_status': newStatus,
        'subscription_start':
            newStatus == 'active' ? now.toIso8601String() : null,
        'subscription_end': newStatus == 'active'
            ? now.add(const Duration(days: 30)).toIso8601String()
            : null,
      });
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management / إدارة المستخدمين')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(user.fullName ?? user.email,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role: ${user.role.toUpperCase()}',
                            style: TextStyle(
                                color: user.role == 'team_leader'
                                    ? Colors.indigo
                                    : Colors.blueGrey,
                                fontWeight: FontWeight.bold)),
                        Text(
                            'Status: ${user.subscriptionStatus.toUpperCase()}'),
                        if (user.subscriptionEnd != null)
                          Text(
                              'Expires: ${DateFormat('yyyy-MM-dd').format(user.subscriptionEnd!)}',
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'set_leader') {
                          _updateUserRole(user, 'team_leader');
                        } else if (value == 'set_sales') {
                          _updateUserRole(user, 'sales_user');
                        } else if (value == 'toggle_sub') {
                          _toggleSubscription(user);
                        } else if (value == 'delete') {
                          _deleteUser(user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'set_leader',
                            child: ListTile(
                                dense: true,
                                leading:
                                    Icon(Icons.stars, color: Colors.indigo),
                                title: Text('Make Team Leader'))),
                        const PopupMenuItem(
                            value: 'set_sales',
                            child: ListTile(
                                dense: true,
                                leading:
                                    Icon(Icons.person, color: Colors.blueGrey),
                                title: Text('Make Sales User'))),
                        PopupMenuItem(
                            value: 'toggle_sub',
                            child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.card_membership),
                                title: Text(user.subscriptionStatus == 'active'
                                    ? 'Deactivate'
                                    : 'Activate'))),
                        const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete User'))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _authRepo.deleteUser(user.id);
        _loadUsers();
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
