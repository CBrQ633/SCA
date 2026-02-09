import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/calls/data/calls_repository.dart';
import 'package:smart_call_assistant/features/calls/data/models/call_list_model.dart';

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
      // Filter for pending items only? Or allow re-calling?
      // For focus mode, let's prioritize 'pending' and 'no_answer'.
      final pendingFn = allItems
          .where((i) => i.status == 'pending' || i.status == 'no_answer')
          .toList();

      if (mounted) {
        setState(() {
          _items = pendingFn;
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
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
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
    // Basic WhatsApp URL
    final cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
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

    // Optimistic Update
    setState(() => _isLoading = true);

    try {
      await _repository.updateItemStatus(currentItem.id, status);

      if (mounted) {
        // Move to next
        if (_currentIndex < _items.length - 1) {
          setState(() {
            _currentIndex++;
            _isLoading = false;
          });
        } else {
          // Done
          setState(() => _isLoading = false);
          _showCompletionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('List Completed!'),
        content: const Text(
            'You have gone through all pending contacts in this list.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to details
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Call Session')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('All caught up!', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              const Text('No pending calls in this list.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = _items[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Call ${_currentIndex + 1}/${_items.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _items.length,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          children: [
            // Contact Card with Animation
            ZoomIn(
              key:
                  ValueKey('contact_card_$_currentIndex'), // Triggers on change
              duration: const Duration(milliseconds: 400),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          currentItem.name != null &&
                                  currentItem.name!.isNotEmpty
                              ? currentItem.name![0]
                              : '?',
                          style: TextStyle(
                            fontSize: 40,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        currentItem.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          currentItem.phone,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: Colors.greenAccent[700]!,
                  onTap: () => _makeCall(currentItem.phone),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366), // WhatsApp color
                  onTap: () => _openWhatsApp(currentItem.phone),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Outcome Buttons
            const Text(
              'LOG OUTCOME',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('called'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo[900],
                      elevation: 0,
                    ),
                    child: const Text('Answered'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('no_answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[900],
                      elevation: 0,
                    ),
                    child: const Text('No Answer'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Skip
                if (_currentIndex < _items.length - 1) {
                  setState(() => _currentIndex++);
                }
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
