import 'package:flutter/material.dart';
import 'package:smart_call_assistant/features/auth/data/auth_repository.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _authRepo.getUsersCount(),
        _callsRepo.getTotalCallsToday(),
        _subRepo.getPendingCount(),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers = results[0] as int;
          _callsToday = results[1] as int;
          _pendingSubs = results[2] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F172A);
    const emerald = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Admin Central', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: navy),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Center(child: AppLogo(size: 60, showText: false)),
                  const SizedBox(height: 40),
                  
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Accounts', _totalUsers.toString(), Icons.supervised_user_circle_outlined, navy)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Performance', _callsToday.toString(), Icons.rocket_launch_outlined, emerald)),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  const Text('CORE OPERATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  
                  _buildActionTile(
                    title: 'Subscription Requests',
                    subtitle: 'Review payments and activation',
                    icon: Icons.auto_awesome_mosaic_outlined,
                    color: Colors.orange,
                    onTap: () => context.push(AppConstants.routeAdminSubscriptions),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    title: 'User Management',
                    subtitle: 'Roles and access control',
                    icon: Icons.shield_moon_outlined,
                    color: navy,
                    onTap: () => context.push(AppConstants.routeAdminUsers),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    title: 'News Center',
                    subtitle: 'Broadcast global updates',
                    icon: Icons.dashboard_customize_outlined,
                    color: emerald,
                    onTap: () => context.push('/admin/news'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), 
          child: Icon(icon, color: color, size: 20)
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        trailing: const Icon(Icons.arrow_forward_rounded, color: Colors.black12, size: 18),
      ),
    );
  }
}
