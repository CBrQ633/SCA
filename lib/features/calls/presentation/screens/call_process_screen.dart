import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
import 'package:smart_call_assistant/core/services/notification_service.dart';
import 'package:smart_call_assistant/core/services/template_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CallProcessScreen extends StatefulWidget {
  final String listId;
  const CallProcessScreen({super.key, required this.listId});

  @override
  State<CallProcessScreen> createState() => _CallProcessScreenState();
}

class _CallProcessScreenState extends State<CallProcessScreen> {
  final CallsRepository _repository = CallsRepository();
  final TemplateService _templateService = TemplateService();
  final _notesController = TextEditingController();
  
  List<CallListItemModel> _items = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  // Stats for the summary
  int _statsAnswered = 0;
  int _statsMissed = 0;
  int _statsWhatsapp = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
    _templateService.seedDefaults();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    try {
      final allItems = await _repository.getListItems(widget.listId);
      final pendingFn = allItems.where((i) => i.status == 'pending' || i.status == 'no_answer').toList();
      
      if (pendingFn.isEmpty) {
        if (mounted) setState(() { _isFinished = true; _isLoading = false; });
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('call_index_${widget.listId}') ?? 0;
      
      if (mounted) {
        setState(() {
          _items = pendingFn;
          _currentIndex = (savedIndex < _items.length) ? savedIndex : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      FirebaseAnalytics.instance.logEvent(name: 'call_initiated');
    }
  }

  void _showWhatsAppOptions(String phoneNumber, String? name) {
    final templates = _templateService.getTemplates();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send WhatsApp / إرسال واتساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (templates.isEmpty)
              const Center(child: Text('No templates found.'))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF128C7E)),
                    title: Text(templates[i], maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendWhatsApp(phoneNumber, name, templates[i]);
                    },
                  ),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Send without template'),
              onTap: () {
                Navigator.pop(ctx);
                _sendWhatsApp(phoneNumber, name, "");
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWhatsApp(String phoneNumber, String? name, String rawMessage) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) cleanPhone = '20${cleanPhone.substring(1)}';
    String message = rawMessage.replaceAll('{name}', name ?? '');
    String encodedMsg = Uri.encodeComponent(message);
    
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      _statsWhatsapp++;
      _updateStatus('whatsapp');
      FirebaseAnalytics.instance.logEvent(name: 'whatsapp_sent');
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
    
    if (status == 'called') _statsAnswered++;
    if (status == 'no_answer') _statsMissed++;

    final currentItem = _items[_currentIndex];
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    
    try {
      await _repository.updateItemStatus(currentItem.id, status, notes: notes);
      _notesController.clear();
      
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (_currentIndex < _items.length - 1) {
          setState(() { _currentIndex++; });
          await prefs.setInt('call_index_${widget.listId}', _currentIndex);
        } else {
          await prefs.remove('call_index_${widget.listId}');
          setState(() => _isFinished = true);
          _showCompletionSummary();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCompletionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Great Work! / عمل رائع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You have finished this list.', style: TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _buildStatRow(Icons.check_circle_rounded, 'Answered:', '$_statsAnswered', Colors.green),
            const SizedBox(height: 12),
            _buildStatRow(Icons.cancel_rounded, 'Missed:', '$_statsMissed', Colors.red),
            const SizedBox(height: 12),
            _buildStatRow(Icons.chat_rounded, 'WhatsApp:', '$_statsWhatsapp', Colors.teal),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.of(ctx).pop(); context.go(AppConstants.routeHome); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('FINISH SESSION'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showReminderPicker() async {
    final currentItem = _items[_currentIndex];
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null) {
        final scheduledDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );

        await NotificationService().scheduleNotification(
          id: currentItem.id.hashCode,
          title: 'Follow-up Reminder 📞',
          body: 'Call ${currentItem.name ?? "Unknown"} (${currentItem.phone}) now!',
          scheduledDate: scheduledDateTime,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_isFinished || _items.isEmpty) return const Scaffold(body: Center(child: Text('Session Ended')));

    final currentItem = _items[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Call ${_currentIndex + 1} / ${_items.length}', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.alarm_add_rounded, color: Colors.orange), onPressed: _showReminderPicker),
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => context.push('/settings/templates')),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value: (_currentIndex + 1) / _items.length, backgroundColor: theme.colorScheme.surface, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.black.withOpacity(0.05))),
              child: Column(
                children: [
                  CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.primary, child: Text(currentItem.name?[0] ?? '?', style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  Text(currentItem.name ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(currentItem.phone, style: TextStyle(fontSize: 18, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildBtn(Icons.call_rounded, 'Call', Colors.blue, () => _makeCall(currentItem.phone)),
              _buildBtn(Icons.chat_rounded, 'WhatsApp', const Color(0xFF128C7E), () => _showWhatsAppOptions(currentItem.phone, currentItem.name)),
            ]),
            const SizedBox(height: 32),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes / ملاحظات', filled: true, fillColor: theme.colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: () => _updateStatus('called'), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('ANSWERED'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => _updateStatus('no_answer'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('MISSED'))),
            ]),
            const SizedBox(height: 16),
            TextButton(onPressed: () => setState(() => _currentIndex < _items.length - 1 ? _currentIndex++ : _showCompletionSummary()), child: const Text('Skip / تخطي')),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(children: [
      InkWell(onTap: onTap, borderRadius: BorderRadius.circular(50), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28))),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }
}
