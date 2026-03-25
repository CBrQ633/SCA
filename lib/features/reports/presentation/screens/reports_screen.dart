import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/reports_repository.dart';
import '../../data/models/report_stats.dart';
import '../../../../core/services/excel_service.dart';
// import '../../../../core/components/app_logo.dart';
import '../../../../shared/services/models.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/data/auth_repository.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsRepository _repository = ReportsRepository();
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = true;
  CallStats? _callStats;
  List<CallEntry> _allCalls = [];
  List<Map<String, dynamic>> _teamMessages = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    try {
      final callStats = await _repository.getCallStats();
      final allCalls = await _repository.getCallDetails();
      
      // Load team messages if user has a leader
      if (user?.leaderId != null) {
        _teamMessages = await _authRepo.getTeamMessages(user!.leaderId!);
      }

      if (!mounted) return;

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
    int totalAttempted = _callStats!.answered + _callStats!.noAnswer;
    if (totalAttempted == 0) return 0.0;
    return (_callStats!.answered / totalAttempted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إنجازاتي وفريقي' : 'My Performance & Team', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadAllData, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 1. Target Progress Card
                  FadeInDown(child: _buildTargetCard(user, theme, isArabic)),
                  const SizedBox(height: 32),
                  
                  // 2. Success Rate Circle
                  _buildSuccessRateCircle(theme),
                  const SizedBox(height: 40),

                  // 3. Team Messages Section
                  if (user?.leaderId != null) ...[
                    _buildSectionHeader(isArabic ? 'رسائل التيم ليدر' : 'Team Leader Messages', theme),
                    const SizedBox(height: 16),
                    _buildTeamMessagesList(theme, isArabic),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader(isArabic ? 'المقاييس الأساسية' : 'Key Metrics', theme),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    theme,
                    isArabic ? 'إجمالي المحاولات' : 'Total Attempted', 
                    (_callStats!.answered + _callStats!.noAnswer).toString(), 
                    Icons.insights_rounded, 
                    theme.colorScheme.primary
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showDetailsDialog('Answered Calls', _allCalls.where((c) => c.isAnswered).toList()),
                          child: _buildStatCard(theme, isArabic ? 'تم الرد' : 'Answered', _callStats?.answered.toString() ?? '0', Icons.phone_callback_rounded, Colors.green, compact: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showDetailsDialog('Missed Calls', _allCalls.where((c) => c.isNotAnswered).toList()),
                          child: _buildStatCard(theme, isArabic ? 'لم يرد' : 'Missed', _callStats?.noAnswer.toString() ?? '0', Icons.phone_missed_rounded, Colors.redAccent, compact: true),
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

  Widget _buildTargetCard(dynamic user, ThemeData theme, bool isArabic) {
    int target = user?.monthlyTarget ?? 0;
    int achieved = (_callStats?.answered ?? 0) + (_callStats?.noAnswer ?? 0);
    double progress = target > 0 ? (achieved / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isArabic ? 'هدفك الشهري' : 'MONTHLY TARGET', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Icon(Icons.track_changes_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text('$achieved / $target', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'لقد حققت ${(progress * 100).toInt()}% من هدفك' : 'You achieved ${(progress * 100).toInt()}% of your target',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMessagesList(ThemeData theme, bool isArabic) {
    if (_teamMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text(isArabic ? 'لا توجد رسائل من الليدر حالياً' : 'No messages from leader yet', style: const TextStyle(fontSize: 12, color: Colors.grey))),
      );
    }

    return Column(
      children: _teamMessages.take(3).map((msg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['content'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, hh:mm a').format(DateTime.parse(msg['created_at'])),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSuccessRateCircle(ThemeData theme) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150, height: 150,
            child: CircularProgressIndicator(
              value: _successRate,
              strokeWidth: 12,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(_successRate * 100).toInt()}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
              const Text('SUCCESS RATE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
          Text(title, style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDetailsDialog(String title, List<CallEntry> filteredCalls) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                ? const Center(child: Text('No records found'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredCalls.length,
                    itemBuilder: (context, index) {
                      final call = filteredCalls[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05), 
                          child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary))
                        ),
                        title: Text(call.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(call.phoneNumber),
                        trailing: Icon(
                          call.isAnswered ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                          color: call.isAnswered ? Colors.green : Colors.redAccent, 
                          size: 20
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
