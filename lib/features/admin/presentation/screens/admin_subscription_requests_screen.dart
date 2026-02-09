import 'package:flutter/material.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';

class AdminSubscriptionRequestsScreen extends StatefulWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  @override
  State<AdminSubscriptionRequestsScreen> createState() =>
      _AdminSubscriptionRequestsScreenState();
}

class _AdminSubscriptionRequestsScreenState
    extends State<AdminSubscriptionRequestsScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _approveRequest(
      String id, String userId, String planType) async {
    try {
      await _repository.approveRequest(id, userId, planType);
      _loadRequests(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request Approved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectRequest(String id) async {
    try {
      await _repository.rejectRequest(id);
      _loadRequests(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request Rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showImageDialog(String imageUrl) {
    if (imageUrl.isEmpty || imageUrl.contains('pending_upload')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image not available or still uploading')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subscriptions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final user = req['users'] as Map<String, dynamic>?;
                    final email = user?['email'] ?? 'Unknown Email';
                    final name = user?['full_name'] ?? 'No Name (Unknown User)';

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('$name ($email)'),
                            subtitle: Text(
                                'Plan: ${req['plan_type']} - Amount: ${req['amount']}'),
                            trailing: Text(
                                req['created_at'].toString().substring(0, 10)),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text('View Proof'),
                                  onPressed: () => _showImageDialog(
                                      req['payment_screenshot_url'] ?? ''),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () => _approveRequest(req['id'],
                                      req['user_id'], req['plan_type']),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => _rejectRequest(req['id']),
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
