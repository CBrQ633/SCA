import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class AdminSubscriptionRequestsScreen extends StatefulWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  @override
  State<AdminSubscriptionRequestsScreen> createState() => _AdminSubscriptionRequestsScreenState();
}

class _AdminSubscriptionRequestsScreenState extends State<AdminSubscriptionRequestsScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _repository.getPendingRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
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

  Future<void> _handleAction(String id, String userId, String plan, bool approve) async {
    try {
      if (approve) {
        await _repository.approveRequest(id, userId, plan);
      } else {
        await _repository.rejectRequest(id);
      }
      _loadRequests();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Approved!' : 'Rejected!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final profile = req['profiles'] as Map<String, dynamic>?;
                    final name = profile?['full_name'] ?? 'Unknown User';
                    final email = profile?['email'] ?? '';

                    return FadeInUp(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$email\nPlan: ${req['plan_type']}'),
                              trailing: Text('${req['amount']} EGP', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(onPressed: () => _showImage(req['payment_screenshot_url']), icon: const Icon(Icons.image), label: const Text('View Receipt')),
                                IconButton(onPressed: () => _handleAction(req['id'], req['user_id'], req['plan_type'], true), icon: const Icon(Icons.check_circle, color: Colors.green)),
                                IconButton(onPressed: () => _handleAction(req['id'], req['user_id'], req['plan_type'], false), icon: const Icon(Icons.cancel, color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
