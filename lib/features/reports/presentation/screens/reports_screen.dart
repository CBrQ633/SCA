import 'package:flutter/material.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير النظام والإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'تصدير إلى Excel',
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final calls = await _repository.getCallDetails();
                await ExcelService()
                    .generateAndShareCallReport(calls, 'Total_Calls');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إنشاء التقرير بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exporting: $e')),
                  );
                }
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'نظرة عامة على النظام', Icons.dashboard_outlined),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'إجمالي المستخدمين',
                      _subscriptionStats?.totalUsers.toString() ?? '0',
                      Icons.people_alt_rounded,
                      Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          'نشطين',
                          _subscriptionStats?.active.toString() ?? '0',
                          Icons.check_circle_rounded,
                          Colors.green,
                          compact: true,
                        ),
                        _buildStatCard(
                          'بانتظار الموافقة',
                          _subscriptionStats?.pending.toString() ?? '0',
                          Icons.hourglass_bottom_rounded,
                          Colors.orange,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader('أداء المكالمات', Icons.call_outlined),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'إجمالي المكالمات المنفذة',
                      _callStats?.totalCalls.toString() ?? '0',
                      Icons.call_rounded,
                      Colors.indigoAccent,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          'تم الرد',
                          _callStats?.answered.toString() ?? '0',
                          Icons.phone_callback_rounded,
                          Colors.teal,
                          compact: true,
                        ),
                        _buildStatCard(
                          'لم يتم الرد',
                          _callStats?.noAnswer.toString() ?? '0',
                          Icons.phone_missed_rounded,
                          Colors.redAccent,
                          compact: true,
                        ),
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
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: compact ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
