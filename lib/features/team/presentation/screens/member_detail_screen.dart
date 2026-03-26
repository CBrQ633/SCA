import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/features/auth/data/user_model.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/team/data/team_repository.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/core/services/excel_service.dart';
import 'package:smart_call_assistant/core/services/notification_service.dart';
import 'package:smart_call_assistant/shared/services/models.dart';
import 'package:animate_do/animate_do.dart';

class MemberDetailScreen extends StatefulWidget {
  final UserModel member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final CallsRepository _callsRepo = CallsRepository();
  final TeamRepository _teamRepo = TeamRepository();
  final ExcelService _excelService = ExcelService();
  
  bool _isLoading = true;
  bool _isDownloading = false;
  Map<String, dynamic> _stats = {};
  int _currentMonthlyTarget = 0;

  @override
  void initState() {
    super.initState();
    _currentMonthlyTarget = widget.member.monthlyTarget;
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _callsRepo.getMemberStats(widget.member.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignExcelFile() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
    if (res != null) {
      final file = File(res.files.single.path!);
      final fileName = res.files.single.name.split('.').first;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading & Assigning file...')));
      try {
        final items = await _callsRepo.importFromExcel(file);
        if (!mounted || !context.mounted) return;
        final leaderId = context.read<AuthProvider>().currentUser!.id; 
        final newList = await _callsRepo.createList(fileName, leaderId, assignedTo: widget.member.id);
        await _callsRepo.addItemsToList(newList.id, items);
        
        await NotificationService().sendNotificationToTeam(
          leaderId: leaderId,
          title: 'New Task Assigned! 📄',
          body: 'Leader added a new call list: $fileName. Start working now!',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File assigned & Notification sent to ${widget.member.fullName}!')));
          _loadStats();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _downloadReport(bool isArabic) async {
    setState(() => _isDownloading = true);
    try {
      final rawDetails = await _callsRepo.getMemberCallDetails(widget.member.id);
      final calls = rawDetails.map((e) => CallEntry.fromJson(e)).toList();
      
      if (calls.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'لا توجد مكالمات مسجلة لهذا المندوب' : 'No calls recorded for this member')));
      } else {
        await _excelService.generateAndShareCallReport(calls, 'Report_${widget.member.fullName}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showEditTargetDialog(bool isArabic) {
    final controller = TextEditingController(text: _currentMonthlyTarget.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isArabic ? 'تعديل المستهدف الشهري' : 'Edit Monthly Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isArabic ? 'عدد المكالمات المستهدف' : 'Target Call Count',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newTarget = int.tryParse(controller.text) ?? _currentMonthlyTarget;
              
              // Capture navigator and messenger before async gap
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                await _teamRepo.updateMemberTarget(widget.member.id, newTarget);
                
                if (!mounted) return;
                setState(() => _currentMonthlyTarget = newTarget);
                navigator.pop(); // Close dialog safely
                messenger.showSnackBar(const SnackBar(content: Text('Target updated successfully!')));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.fullName ?? 'Details')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              FadeInDown(child: _buildProfileHeader(theme, isArabic)),
              const SizedBox(height: 32),
              _buildStatsGrid(theme, isArabic),
              const SizedBox(height: 40),
              _buildActionButtons(theme, isArabic),
            ],
          ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
      child: Column(children: [
        CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.primary, child: Text(widget.member.fullName?[0].toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 32))),
        const SizedBox(height: 16),
        Text(widget.member.fullName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(widget.member.scaId ?? '', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        _buildTargetProgress(theme, isArabic),
      ]),
    );
  }

  Widget _buildTargetProgress(ThemeData theme, bool isArabic) {
    int totalCalls = (_stats['answered'] ?? 0) + (_stats['missed'] ?? 0);
    double progress = _currentMonthlyTarget == 0 ? 0.0 : totalCalls / _currentMonthlyTarget;
    if (progress > 1.0) progress = 1.0;

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isArabic ? 'التقدم نحو الهدف' : 'Target Progress', style: const TextStyle(fontSize: 12)),
        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Colors.orange))),
    ]);
  }

  Widget _buildStatsGrid(ThemeData theme, bool isArabic) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.5,
      children: [
        _buildStatCard(isArabic ? 'إجمالي المكالمات' : 'Total Calls', '${_stats['total']}', Colors.blue),
        _buildStatCard(isArabic ? 'تم الرد' : 'Answered', '${_stats['answered']}', Colors.green),
        _buildStatCard(isArabic ? 'لم يتم الرد' : 'Missed', '${_stats['missed']}', Colors.red),
        GestureDetector(
          onTap: () => _showEditTargetDialog(isArabic),
          child: _buildStatCard(isArabic ? 'المستهدف' : 'Monthly Target', '$_currentMonthlyTarget', Colors.orange, isEditable: true),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {bool isEditable = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: isEditable ? Border.all(color: color.withValues(alpha: 0.3), width: 1) : null, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            if (isEditable) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit_note_rounded, size: 16, color: color),
            ]
          ],
        ),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isArabic) {
    return Column(children: [
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: _assignExcelFile,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(isArabic ? 'إرسال ملف عمل للمندوب' : 'Assign Excel File to Member'),
          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 56,
        child: TextButton.icon(
          onPressed: _isDownloading ? null : () => _downloadReport(isArabic),
          icon: _isDownloading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download_outlined),
          label: Text(isArabic ? 'سحب تقرير المندوب (Excel)' : 'Download Member Report'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
        ),
      ),
    ]);
  }
}
