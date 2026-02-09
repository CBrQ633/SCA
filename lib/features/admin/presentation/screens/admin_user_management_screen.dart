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
  final AuthRepository _roleRepository = AuthRepository();
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
      final users = await _roleRepository.getAllUsers();
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

  Future<void> _toggleSubscription(UserModel user) async {
    final newStatus =
        user.subscriptionStatus == 'active' ? 'inactive' : 'active';
    try {
      final now = DateTime.now();
      await _roleRepository.updateUser(user.id, {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    try {
      await _roleRepository.updateUser(user.id, {'role': newRole});
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(user.fullName ?? user.email,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user.email}'),
                            Text('Role: ${user.role.toUpperCase()}'),
                            Text(
                                'Status: ${user.subscriptionStatus.toUpperCase()}'),
                            if (user.subscriptionEnd != null)
                              Text(
                                  'Expires: ${DateFormat('yyyy-MM-dd').format(user.subscriptionEnd!)}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle_sub') {
                              _toggleSubscription(user);
                            } else if (value == 'toggle_role') {
                              _toggleRole(user);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle_sub',
                              child: Text(user.subscriptionStatus == 'active'
                                  ? 'Cancel Subscription'
                                  : 'Start Subscription'),
                            ),
                            PopupMenuItem(
                              value: 'toggle_role',
                              child: Text(user.role == 'admin'
                                  ? 'Revoke Admin'
                                  : 'Make Admin'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
