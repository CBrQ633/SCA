import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/components/app_logo.dart';
import '../../../../features/auth/presentation/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isLoading = true;
  CallStats? _callStats;
  SubscriptionStats? _subscriptionStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final callStats = await _repository.getCallStats();
      
      // ✅ Fix: Only load system-wide stats if Admin
      SubscriptionStats? subStats;
      if (authProvider.isAdmin) {
        subStats = await _repository.getSubscriptionStats();
      }

      if (mounted) {
        setState(() {
          _callStats = callStats;
          _subscriptionStats = subStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _successRate {
    if (_callStats == null || _callStats!.totalCalls == 0) return 0.0;
    return (_callStats!.answered / _callStats!.totalCalls);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'System Reports / تقارير النظام' : 'My Performance / إنجازاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final calls = await _repository.getCallDetails();
                await ExcelService().generateAndShareCallReport(calls, 'SCA_Report');
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
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
                    FadeInDown(child: const Center(child: AppLogo(size: 60, showText: true))),
                    const SizedBox(height: 32),
                    
                    // Personal Success Rate (Visible to everyone)
                    FadeInUp(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), shape: BoxShape.circle),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140, height: 140,
                                child: CircularProgressIndicator(
                                  value: _successRate,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${(_successRate * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                  const Text('Success Rate', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ✅ Fix: Only show System Overview to Admin
                    if (isAdmin && _subscriptionStats != null) ...[
                      _buildSectionHeader('System Overview / نظرة عامة', Icons.analytics_outlined),
                      const SizedBox(height: 16),
                      _buildStatCard('Total Users / المستخدمين', _subscriptionStats?.totalUsers.toString() ?? '0', Icons.group, theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Active / نشط', _subscriptionStats?.active.toString() ?? '0', Icons.check_circle, theme.colorScheme.secondary, compact: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Pending / معلق', _subscriptionStats?.pending.toString() ?? '0', Icons.pending, Colors.orange, compact: true)),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    _buildSectionHeader('Call Statistics / إحصائيات الاتصال', Icons.call_outlined),
                    const SizedBox(height: 16),
                    _buildStatCard('Total Logged / إجمالي العمليات', _callStats?.totalCalls.toString() ?? '0', Icons.phone_forwarded, theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Answered / رد', _callStats?.answered.toString() ?? '0', Icons.phone_callback, theme.colorScheme.secondary, compact: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Missed / لم يرد', _callStats?.noAnswer.toString() ?? '0', Icons.phone_missed, Colors.redAccent, compact: true)),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F172A)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: compact ? 18 : 22),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontSize: compact ? 11 : 13, color: Colors.grey[600], fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
