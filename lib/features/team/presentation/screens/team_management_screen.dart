import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/data/user_model.dart';
import '../../team/data/team_repository.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final TeamRepository _repository = TeamRepository();
  List<UserModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final leaderId = context.read<AuthProvider>().currentUser?.id;
    if (leaderId == null) return;

    setState(() => _isLoading = true);
    try {
      final members = await _repository.getTeamMembers(leaderId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMember() async {
    final leaderId = context.read<AuthProvider>().currentUser?.id;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member / إضافة عضو'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter SCA ID (e.g. SCA-A1B2)',
            prefixIcon: Icon(Icons.badge_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(ctx);
              _performAdd(leaderId!, controller.text.trim());
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAdd(String leaderId, String scaId) async {
    setState(() => _isLoading = true);
    try {
      await _repository.addMemberByScaId(leaderId, scaId);
      _loadTeam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _removeMember(UserModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove ${member.fullName} from your team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('REMOVE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _repository.removeMember(member.id);
      _loadTeam();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team / فريقي'),
        actions: [
          IconButton(onPressed: _loadTeam, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(member.fullName?[0].toUpperCase() ?? 'U', 
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(member.fullName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(member.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                            onPressed: () => _removeMember(member),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        label: const Text('Add Member'),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Your team is empty', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Give your SCA ID to members to join', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
