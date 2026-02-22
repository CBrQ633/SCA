import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/auth/data/auth_repository.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final CallsRepository _callsRepo = CallsRepository();
  final SubscriptionRepository _subRepo = SubscriptionRepository();

  int _totalUsers = 0;
  int _callsToday = 0;
  int _pendingSubs = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _authRepo.getUsersCount(),
        _callsRepo.getTotalCallsToday(),
        _subRepo.getPendingCount(),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers = results[0];
          _callsToday = results[1];
          _pendingSubs = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Central / لوحة التحكم'),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: AppLogo(size: 30, showText: false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      child: Text(
                        'System Statistics / إحصائيات النظام',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMainStats(theme),
                    const SizedBox(height: 32),
                    FadeInUp(
                      child: _buildQuickActions(theme),
                    ),
                    const SizedBox(height: 32),
                    _buildActivitySummary(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainStats(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FadeInLeft(
                child: _StatCard(
                  title: 'Total Users / المستخدمين',
                  value: _totalUsers.toString(),
                  icon: Icons.people_alt_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FadeInRight(
                child: _StatCard(
                  title: 'Calls Today / اتصالات اليوم',
                  value: _callsToday.toString(),
                  icon: Icons.call_made_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Tasks / مهام معلقة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Approve Subscriptions / تفعيل الاشتراكات',
          subtitle: '$_pendingSubs pending requests / طلبات بانتظار الموافقة',
          icon: Icons.verified_user_rounded,
          color: Colors.orangeAccent,
          badge: _pendingSubs > 0 ? _pendingSubs : null,
          onTap: () {
            // Navigate to Subscription Management
          },
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'User Management / إدارة المستخدمين',
          subtitle: 'View and manage all users / عرض وإدارة الأعضاء',
          icon: Icons.admin_panel_settings_rounded,
          color: theme.colorScheme.primary,
          onTap: () {
            // Navigate to User Management
          },
        ),
      ],
    );
  }

  Widget _buildActivitySummary(ThemeData theme) {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_graph_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'System Activity is Stable / حالة النظام مستقرة',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const Text(
              'All services are running smoothly.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? badge;
  final VoidCallback onTap;

  const _ActionTile({required this.title, required this.subtitle, required this.icon, required this.color, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                child: Text(badge.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
