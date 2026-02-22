import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/components/app_logo.dart';

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
      final callStats = await _repository.getCallStats();
      final subStats = await _repository.getSubscriptionStats();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Insights / التقارير'),
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
                    FadeInDown(
                      child: Center(child: AppLogo(size: 60, showText: true)),
                    ),
                    const SizedBox(height: 32),

                    // Success Rate Circular Indicator
                    FadeInUp(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: _successRate,
                                  strokeWidth: 12,
                                  backgroundColor: theme.colorScheme.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(_successRate * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                  const Text('Success Rate', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const Text('معدل النجاح', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

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
                    _buildSectionHeader('Call Performance / أداء الاتصالات', Icons.call_outlined),
                    const SizedBox(height: 16),
                    _buildStatCard('Total Executed / إجمالي المنفذ', _callStats?.totalCalls.toString() ?? '0', Icons.phone_forwarded, theme.colorScheme.primary),
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
    return FadeInLeft(
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool compact = false}) {
    return FadeInUp(
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: compact ? 18 : 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: compact ? 12 : 14, color: Colors.grey[600], fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}
