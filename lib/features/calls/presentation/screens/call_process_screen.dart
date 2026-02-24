import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class CallProcessScreen extends StatefulWidget {
  final String listId;
  const CallProcessScreen({super.key, required this.listId});

  @override
  State<CallProcessScreen> createState() => _CallProcessScreenState();
}

class _CallProcessScreenState extends State<CallProcessScreen> {
  final CallsRepository _repository = CallsRepository();
  List<CallListItemModel> _items = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
  }

  Future<void> _loadPendingItems() async {
    try {
      final allItems = await _repository.getListItems(widget.listId);
      final pendingFn = allItems
          .where((i) => i.status == 'pending' || i.status == 'no_answer')
          .toList();

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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = '20${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      _updateStatus('whatsapp');
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_items.isEmpty) return;
    final currentItem = _items[_currentIndex];
    
    // Show local loading only for the action
    try {
      await _repository.updateItemStatus(currentItem.id, status);
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (_currentIndex < _items.length - 1) {
          final nextIndex = _currentIndex + 1;
          await prefs.setInt('call_index_${widget.listId}', nextIndex);
          setState(() {
            _currentIndex = nextIndex;
          });
        } else {
          await prefs.remove('call_index_${widget.listId}');
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('List Completed! / انتهيت!'),
        content: const Text('Great job! All contacts have been processed.\nأحسنت! لقد انتهيت من جميع جهات الاتصال.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back / العودة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Finished'), backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 80, showText: false),
              const SizedBox(height: 24),
              const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final currentItem = _items[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // White-Grey for clean look
      appBar: AppBar(
        title: Text('Call ${_currentIndex + 1} / ${_items.length}', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _items.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Clean Contact Card (No Animation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(currentItem.name?[0] ?? '?', style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  Text(currentItem.name ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text(currentItem.phone, style: TextStyle(fontSize: 18, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBtn(Icons.call, 'Call', Colors.blue, () => _makeCall(currentItem.phone)),
                _buildBtn(Icons.chat, 'WhatsApp', const Color(0xFF128C7E), () => _openWhatsApp(currentItem.phone)),
              ],
            ),
            const SizedBox(height: 40),
            // Results
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('called'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Answered / تم الرد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('no_answer'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('No Answer / لم يرد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => setState(() => _currentIndex < _items.length - 1 ? _currentIndex++ : _showCompletionDialog()), child: const Text('Skip / تخطي', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
