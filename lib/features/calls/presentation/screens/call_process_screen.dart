import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';

class CallProcessScreen extends StatefulWidget {
  final String listId;
  const CallProcessScreen({super.key, required this.listId});

  @override
  State<CallProcessScreen> createState() => _CallProcessScreenState();
}

class _CallProcessScreenState extends State<CallProcessScreen> {
  final CallsRepository _repository = CallsRepository();
  final _notesController = TextEditingController();
  List<CallListItemModel> _items = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
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
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) cleanPhone = '20${cleanPhone.substring(1)}';
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      _updateStatus('whatsapp');
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
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
          _showCompletionDialog();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('All Done! / انتهيت', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('List completed successfully.\nلقد أكملت جميع جهات الاتصال.'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.of(ctx).pop(); context.go(AppConstants.routeHome); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('OK / حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_isFinished || _items.isEmpty) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const AppLogo(size: 80, showText: false), const SizedBox(height: 24), const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 24), ElevatedButton(onPressed: () => context.go(AppConstants.routeHome), child: const Text('Return Home'))])));
    }

    final currentItem = _items[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Call ${_currentIndex + 1} / ${_items.length}', style: const TextStyle(fontSize: 16)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value: (_currentIndex + 1) / _items.length, backgroundColor: theme.colorScheme.surface, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardTheme.color, 
                borderRadius: BorderRadius.circular(28), 
                border: Border.all(color: Colors.black.withOpacity(0.05)), // ✅ Fixed: Explicit Border
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]
              ),
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
              _buildBtn(Icons.chat_rounded, 'WhatsApp', const Color(0xFF128C7E), () => _openWhatsApp(currentItem.phone)),
            ]),
            const SizedBox(height: 32),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes / ملاحظات (Optional)',
                hintText: 'Interested, call next week...',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: () => _updateStatus('called'), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('ANSWERED'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => _updateStatus('no_answer'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('MISSED'))),
            ]),
            const SizedBox(height: 16),
            TextButton(onPressed: () => setState(() => _currentIndex < _items.length - 1 ? _currentIndex++ : _showCompletionDialog()), child: const Text('Skip / تخطي')),
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
