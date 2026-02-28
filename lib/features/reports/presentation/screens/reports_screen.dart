import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/components/app_logo.dart';
import '../../../../features/auth/presentation/auth_provider.dart';
import '../../../../shared/services/models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isLoading = true;
  CallStats? _callStats;
  List<CallEntry> _allCalls = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final callStats = await _repository.getCallStats();
      final allCalls = await _repository.getCallDetails();
      if (mounted) {
        setState(() {
          _callStats = callStats;
          _allCalls = allCalls;
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

  void _showDetailsDialog(String title, List<CallEntry> filteredCalls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ExcelService().generateAndShareCallReport(filteredCalls, title);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredCalls.isEmpty 
                ? const Center(child: Text('No records found / لا توجد سجلات'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredCalls.length,
                    itemBuilder: (context, index) {
                      final call = filteredCalls[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFFF1F5F9), child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.black))),
                        title: Text(call.customerName ?? 'Unknown'),
                        subtitle: Text(call.phoneNumber),
                        trailing: Icon(call.isAnswered ? Icons.check_circle : Icons.cancel, color: call.isAnswered ? Colors.green : Colors.red, size: 16),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Performance / إنجازاتي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Center(child: AppLogo(size: 60, showText: true)),
                  const SizedBox(height: 40),
                  
                  // Circular Progress
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150, height: 150,
                          child: CircularProgressIndicator(
                            value: _successRate,
                            strokeWidth: 12,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(_successRate * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const Text('Success Rate', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildSectionHeader('Call Statistics / الإحصائيات'),
                  const SizedBox(height: 16),
                  
                  _buildStatCard('Total Logged', _callStats?.totalCalls.toString() ?? '0', Icons.phone_android_rounded, const Color(0xFF0F172A)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showDetailsDialog('Answered Calls', _allCalls.where((c) => c.isAnswered).toList()),
                          child: _buildStatCard('Answered', _callStats?.answered.toString() ?? '0', Icons.phone_callback_rounded, const Color(0xFF10B981), compact: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showDetailsDialog('Missed Calls', _allCalls.where((c) => c.isNotAnswered).toList()),
                          child: _buildStatCard('Missed', _callStats?.noAnswer.toString() ?? '0', Icons.phone_missed_rounded, Colors.redAccent, compact: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
