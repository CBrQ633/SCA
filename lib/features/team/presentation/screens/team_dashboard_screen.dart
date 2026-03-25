import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/auth/data/auth_repository.dart';
import 'package:smart_call_assistant/features/auth/data/user_model.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/team/presentation/screens/member_detail_screen.dart';
import 'package:smart_call_assistant/core/services/notification_service.dart';
import 'package:animate_do/animate_do.dart';

class TeamDashboardScreen extends StatefulWidget {
  const TeamDashboardScreen({super.key});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final CallsRepository _callsRepo = CallsRepository();
  
  List<UserModel> _teamMembers = [];
  bool _isLoading = true;
  int _totalTeamCallsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    final leaderId = context.read<AuthProvider>().currentUser?.id;
    if (leaderId == null) return;
    setState(() => _isLoading = true);
    try {
      final members = await _authRepo.getMyTeamMembers(leaderId);
      final callsToday = await _callsRepo.getTotalCallsToday(); 
      if (mounted) {
        setState(() {
          _teamMembers = members;
          _totalTeamCallsToday = callsToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddMemberDialog(BuildContext context, bool isArabic) {
    final controller = TextEditingController();
    UserModel? foundUser;
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isArabic ? 'إضافة مندوب بالكود' : 'Add Member by ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'SCA-XXXXXX',
                  labelText: isArabic ? 'كود المندوب' : 'Member SCA ID',
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                  suffixIcon: IconButton(
                    icon: isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded),
                    onPressed: () async {
                      if (controller.text.isEmpty) return;
                      setDialogState(() => isSearching = true);
                      final user = await _authRepo.findUserByScaId(controller.text.trim());
                      setDialogState(() { foundUser = user; isSearching = false; });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              if (foundUser != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(foundUser!.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(foundUser!.email, style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(8)),
                      onPressed: () async {
                        final leaderId = context.read<AuthProvider>().currentUser!.id;
                        await _authRepo.addMemberToTeam(leaderId, foundUser!.id);
                        if (mounted && context.mounted) {
                          Navigator.pop(ctx);
                          _loadTeamData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'تمت إضافة المندوب لفريقك' : 'Member added successfully!')));
                        }
                      },
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, bool isArabic) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'رسالة الفريق' : 'Team Message'), 
        content: TextField(
          controller: controller, 
          maxLines: 3, 
          decoration: InputDecoration(hintText: isArabic ? 'اكتب هنا...' : 'Write here...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')), 
          ElevatedButton(
            onPressed: () async { 
              if (controller.text.isEmpty) return;
              final leaderId = context.read<AuthProvider>().currentUser!.id;
              
              // 1. Save to DB
              await _authRepo.sendBroadcast(leaderId, controller.text);
              
              // 2. Send Push Notification ✅
              await NotificationService().sendNotificationToTeam(
                leaderId: leaderId,
                title: 'Leader Update 📣',
                body: controller.text,
              );

              if (mounted && context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to everyone!')));
              }
            }, 
            child: Text(isArabic ? 'إرسال' : 'Send')
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إدارة الفريق' : 'Team Management', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue), onPressed: () => _showAddMemberDialog(context, isArabic)),
          IconButton(onPressed: _loadTeamData, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadTeamData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeaderStats(theme, isArabic),
            const SizedBox(height: 24),
            _buildBroadcastCard(theme, isArabic),
            const SizedBox(height: 32),
            Text(isArabic ? 'أعضاء الفريق والتقدم' : 'Team Members & Progress', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_teamMembers.isEmpty) _buildEmptyState(theme, isArabic)
            else ..._teamMembers.map((member) => FadeInUp(
              child: _buildMemberCard(member, theme, isArabic),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(UserModel member, ThemeData theme, bool isArabic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemberDetailScreen(member: member)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), child: Text(member.fullName?[0].toUpperCase() ?? 'M')),
                title: Text(member.fullName ?? member.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(member.scaId ?? '', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isArabic ? 'التقدم نحو الهدف:' : 'Target Progress:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${member.monthlyTarget} Calls', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: 0.1, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Colors.orange)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(isArabic ? 'الفريق' : 'Team', _teamMembers.length.toString(), Icons.people_alt_rounded),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem(isArabic ? 'إنجاز اليوم' : 'Daily Work', '$_totalTeamCallsToday', Icons.bolt_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(children: [Icon(icon, color: Colors.white, size: 24), const SizedBox(height: 8), Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold))]);
  }

  Widget _buildBroadcastCard(ThemeData theme, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.campaign_rounded, color: Colors.orange), const SizedBox(width: 12), Text(isArabic ? 'رسالة جماعية' : 'Broadcast', style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        Text(isArabic ? 'أرسل تنبيهات لجميع المناديب في فريقك' : 'Send alerts to all team members', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showBroadcastDialog(context, isArabic), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: Text(isArabic ? 'إرسال رسالة' : 'Send Message'))),
      ]),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isArabic) {
    return Center(child: Column(children: [const SizedBox(height: 40), Icon(Icons.group_off_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.1)), const SizedBox(height: 16), Text(isArabic ? 'لا يوجد أعضاء في فريقك' : 'No team members', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
  }
}
