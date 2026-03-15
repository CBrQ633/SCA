import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AdminSubscriptionRequestsScreen extends StatefulWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  @override
  State<AdminSubscriptionRequestsScreen> createState() => _AdminSubscriptionRequestsScreenState();
}

class _AdminSubscriptionRequestsScreenState extends State<AdminSubscriptionRequestsScreen> with SingleTickerProviderStateMixin {
  final SubscriptionRepository _repository = SubscriptionRepository();
  late TabController _tabController;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _handleAction(Map<String, dynamic> req, bool approve) async {
    final String id = req['id'];
    final String userId = req['user_id'];
    final String plan = req['plan_type'];

    if (!approve) {
      final reason = await _showRejectReasonDialog();
      if (reason == null) return; // User cancelled
      
      setState(() => _isLoading = true);
      await _repository.rejectRequest(id, userId, reason: reason);
    } else {
      setState(() => _isLoading = true);
      await _repository.approveRequest(id, userId, plan);
    }
    
    await _loadRequests();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Request Approved! / تم التفعيل' : 'Request Rejected / تم الرفض'))
      );
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    String? selectedReason;
    final reasons = [
      'Image not clear / الصورة غير واضحة',
      'Amount incorrect / المبلغ غير صحيح',
      'Transaction not found / العملية غير موجودة',
      'Other / سبب آخر'
    ];

    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reason / سبب الرفض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((r) => ListTile(
            title: Text(r, style: const TextStyle(fontSize: 14)),
            onTap: () => Navigator.pop(ctx, r),
          )).toList(),
        ),
      ),
    );
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: Image.network(url, fit: foundation.kIsWeb ? BoxFit.contain : null)),
            ),
            PositionBag(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
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
        title: const Text('Subscription Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'History (Coming Soon)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final profile = req['profiles'] as Map<String, dynamic>?;
                      final name = profile?['full_name'] ?? 'Unknown User';
                      final email = profile?['email'] ?? '';
                      final date = DateTime.parse(req['created_at']);

                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                  child: Text(name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(email, style: TextStyle(color: theme.hintColor)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text(req['plan_type'].toUpperCase(), style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 10)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('MMM dd, hh:mm a').format(date), style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text('${req['amount']} EGP', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => _showImage(req['payment_screenshot_url']),
                                        icon: const Icon(Icons.receipt_long_rounded),
                                        label: const Text('View Receipt'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: () => _handleAction(req, false),
                                      icon: const Icon(Icons.close_rounded),
                                      style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: () => _handleAction(req, true),
                                      icon: const Icon(Icons.check_rounded),
                                      style: IconButton.styleFrom(backgroundColor: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('All caught up! No pending requests.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Fixed minor helper for the dialog stack
class PositionBag extends StatelessWidget {
  final double? top, right, bottom, left;
  final Widget child;
  const PositionBag({super.key, this.top, this.right, this.bottom, this.left, required this.child});
  @override Widget build(BuildContext context) => Positioned(top: top, right: right, bottom: bottom, left: left, child: child);
}
