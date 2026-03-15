import 'package:flutter/material.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/components/app_logo.dart';
import '../../../../shared/services/models.dart';
import 'package:animate_do/animate_do.dart';

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
    setState(() => _isLoading = true);
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
    // Success rate based on Answered / (Answered + No Answer)
    int totalAttempted = _callStats!.answered + _callStats!.noAnswer;
    if (totalAttempted == 0) return 0.0;
    return (_callStats!.answered / totalAttempted);
  }

  void _showDetailsDialog(String title, List<CallEntry> filteredCalls) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    icon: Icon(Icons.file_download_outlined, color: theme.colorScheme.secondary),
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
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.05), 
                          child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary))
                        ),
                        title: Text(call.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${call.phoneNumber}\n${call.listName ?? ""}', style: const TextStyle(fontSize: 11)),
                        trailing: Icon(
                          call.isAnswered ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                          color: call.isAnswered ? Colors.green : Colors.redAccent, 
                          size: 20
                        ),
                        isThreeLine: true,
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
      appBar: AppBar(
        title: const Text('My Performance / إنجازاتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  FadeInDown(child: const Center(child: AppLogo(size: 60, showText: true))),
                  const SizedBox(height: 40),
                  
                  // Circular Progress Dashboard
                  FadeIn(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180, height: 180,
                            child: CircularProgressIndicator(
                              value: _successRate,
                              strokeWidth: 15,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_successRate * 100).toInt()}%', 
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)
                              ),
                              const Text('SUCCESS RATE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildSectionHeader('Key Metrics / المقاييس الأساسية', theme),
                  const SizedBox(height: 16),
                  
                  FadeInUp(
                    child: _buildStatCard(
                      theme,
                      'Total Attempted', 
                      (_callStats!.answered + _callStats!.noAnswer).toString(), 
                      Icons.insights_rounded, 
                      theme.colorScheme.primary
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: FadeInLeft(
                          child: InkWell(
                            onTap: () => _showDetailsDialog('Answered Calls', _allCalls.where((c) => c.isAnswered).toList()),
                            child: _buildStatCard(theme, 'Answered', _callStats?.answered.toString() ?? '0', Icons.phone_callback_rounded, Colors.green, compact: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeInRight(
                          child: InkWell(
                            onTap: () => _showDetailsDialog('Missed Calls', _allCalls.where((c) => c.isNotAnswered).toList()),
                            child: _buildStatCard(theme, 'Missed', _callStats?.noAnswer.toString() ?? '0', Icons.phone_missed_rounded, Colors.redAccent, compact: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  FadeInUp(
                    child: InkWell(
                      onTap: () => _showDetailsDialog('Full Call History', _allCalls),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('View All History / سجل المكالمات كامل', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 1.2));
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, 
        borderRadius: BorderRadius.circular(24),
        border: theme.cardTheme.shape is RoundedRectangleBorder 
          ? (theme.cardTheme.shape as RoundedRectangleBorder).side 
          : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (!compact) Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.hintColor.withOpacity(0.3)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
          Text(title, style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
