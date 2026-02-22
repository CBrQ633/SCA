import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = '20${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }

    // Direct link to open chat without prefilled message
    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      _updateStatus('whatsapp');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')));
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_items.isEmpty) return;
    final currentItem = _items[_currentIndex];
    setState(() => _isLoading = true);

    try {
      await _repository.updateItemStatus(currentItem.id, status);
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (_currentIndex < _items.length - 1) {
          final nextIndex = _currentIndex + 1;
          await prefs.setInt('call_index_${widget.listId}', nextIndex);
          setState(() {
            _currentIndex = nextIndex;
            _isLoading = false;
          });
        } else {
          await prefs.remove('call_index_${widget.listId}');
          setState(() => _isLoading = false);
          _showCompletionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('List Completed! / اكتملت القائمة'),
        content: const Text('You have gone through all pending contacts.\nلقد انتهيت من جميع جهات الاتصال المعلقة.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Great! / رائع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Finished')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 80, showText: false),
              const SizedBox(height: 24),
              const Text('All caught up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('No pending calls in this list.'),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final currentItem = _items[_currentIndex];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Call ${_currentIndex + 1} / ${_items.length}'),
        actions: const [Padding(padding: EdgeInsets.all(8.0), child: AppLogo(size: 35, showText: false))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _items.length,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
        child: Column(
          children: [
            ZoomIn(
              key: ValueKey('card_$_currentIndex'),
              duration: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        currentItem.name?.isNotEmpty == true ? currentItem.name![0] : '?',
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentItem.name ?? 'Unknown Customer',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(currentItem.phone, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(icon: Icons.call, label: 'Call', color: Colors.blue[700]!, onTap: () => _makeCall(currentItem.phone)),
                _buildActionButton(icon: Icons.chat, label: 'WhatsApp', color: const Color(0xFF128C7E), onTap: () => _openWhatsApp(currentItem.phone)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('RESULT / النتيجة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('called'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white),
                    child: const Text('Answered / تم الرد'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('no_answer'),
                    child: const Text('No Answer / لم يرد'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex < _items.length - 1 ? _currentIndex++ : _showCompletionDialog()),
              child: const Text('Skip / تخطي'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
