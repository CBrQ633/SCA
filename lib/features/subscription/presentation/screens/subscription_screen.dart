import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_call_assistant/features/auth/data/user_model.dart';
import 'package:smart_call_assistant/core/utils/app_notifications.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  bool _isLoading = false;
  String? _selectedPlan;
  File? _proofImage;

  // Prices and Plans
  static const Map<String, double> prices = {
    'sales_monthly': 100.0,
    'sales_quarterly': 250.0,
    'leader_monthly': 200.0,
    'leader_quarterly': 500.0,
  };

  static const String vodafoneCash = '01080305645';
  static const String instapay = '01550381486';
  static const String adminWhatsapp = '201550381486';

  Future<void> _contactSupport() async {
    final message = Uri.encodeComponent("Hello SCA Support, I have a question regarding my subscription.");
    final Uri url = Uri.parse("https://wa.me/$adminWhatsapp?text=$message");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _proofImage = File(pickedFile.path));
    }
  }

  Future<void> _submitRequest(UserModel user) async {
    if (_selectedPlan == null || _proofImage == null) return;
    
    setState(() => _isLoading = true);
    try {
      double amount = prices[_selectedPlan] ?? 0.0;
      // Plan type format: "sales_monthly", "leader_quarterly" etc.
      await _repository.createSubscriptionRequest(
        userId: user.id,
        planType: _selectedPlan!,
        amount: amount,
        proofImage: _proofImage!,
      );
      if (mounted) {
        AppNotifications.showSuccess(context, 'Request submitted! / تم إرسال الطلب');
        setState(() { _selectedPlan = null; _proofImage = null; });
        await context.read<AuthProvider>().refreshUser();
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isActive = user?.isSubscriptionActive ?? false;
    final isPending = user?.subscriptionStatus == 'pending';
    final isRejected = user?.subscriptionStatus == 'rejected';
    
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Subscription / الباقات والاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(user, isActive, isPending, isRejected),
            const SizedBox(height: 24),
            _buildSupportButton(theme),
            const SizedBox(height: 32),
            if (!isPending) ...[
              const Text('Standard Sales Plans / باقات المناديب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              _buildPlanTile('Sales: 1 Month / شهر مندوب', '100 EGP', 'sales_monthly'),
              const SizedBox(height: 8),
              _buildPlanTile('Sales: 3 Months / ٣ شهور مندوب', '250 EGP', 'sales_quarterly'),
              
              const SizedBox(height: 24),
              const Text('Team Leader Plans / باقات تيم ليدر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
              const SizedBox(height: 12),
              _buildPlanTile('Leader: 1 Month / شهر ليدر', '200 EGP', 'leader_monthly', color: Colors.indigo),
              const SizedBox(height: 8),
              _buildPlanTile('Leader: 3 Months / ٣ شهور ليدر', '500 EGP', 'leader_quarterly', color: Colors.indigo),

              const SizedBox(height: 24),
              _buildPaymentInfoCard(),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: _proofImage != null ? theme.colorScheme.secondary : Colors.grey.withOpacity(0.3), width: 2)
                  ),
                  child: _proofImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_proofImage!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.upload_file, size: 32, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        const Text('Upload Receipt / ارفع الإيصال', style: TextStyle(fontWeight: FontWeight.bold))
                      ]),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedPlan == null || _proofImage == null ? null : () => _submitRequest(user!),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REQUEST / إرسال الطلب'),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Your request is being reviewed...\nجاري مراجعة طلبك...', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton(ThemeData theme) {
    return InkWell(
      onTap: _contactSupport,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Colors.green),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help or custom plan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Contact admin on WhatsApp', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chat_rounded, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(UserModel? user, bool isActive, bool isPending, bool isRejected) {
    Color cardColor = Colors.red.withOpacity(0.1);
    Color borderColor = Colors.redAccent;
    IconData icon = Icons.error_outline;
    String statusText = 'Inactive / غير نشط';

    if (isActive) {
      cardColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      icon = Icons.verified;
      statusText = 'Account Active / الحساب نشط';
    } else if (isPending) {
      cardColor = Colors.amber.withOpacity(0.1);
      borderColor = Colors.amber;
      icon = Icons.timer;
      statusText = 'Pending Review / قيد المراجعة';
    } else if (isRejected) {
      cardColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      icon = Icons.cancel;
      statusText = 'Request Rejected / تم رفض الطلب';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor),
              const SizedBox(width: 12),
              Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Text('Current Role: ${user?.role.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          if (isRejected && user?.subscriptionRejectReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
              child: Text('Reason / السبب: ${user!.subscriptionRejectReason}', style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
          if (isActive && user?.subscriptionEnd != null) ...[
            const SizedBox(height: 8),
            Text('Expires: ${DateFormat('yyyy-MM-dd').format(user!.subscriptionEnd!)}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          ]
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        children: [
          _buildPaymentRow('Vodafone Cash', vodafoneCash, Colors.red),
          const Divider(),
          _buildPaymentRow('InstaPay', instapay, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, Color color) {
    return ListTile(
      leading: Icon(Icons.payment, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildPlanTile(String title, String price, String value, {Color? color}) {
    final isSelected = _selectedPlan == value;
    final theme = Theme.of(context);
    final borderColor = isSelected ? (color ?? theme.colorScheme.secondary) : Colors.grey.withOpacity(0.1);

    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1)
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: borderColor),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(price, style: TextStyle(color: color ?? theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}
