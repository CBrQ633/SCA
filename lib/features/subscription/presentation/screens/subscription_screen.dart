import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  static const double priceMonthly = 100.0;
  static const double priceQuarterly = 250.0;
  static const String vodafoneCash = '01080305645';
  static const String instapay = '01550381486';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _proofImage = File(pickedFile.path));
    }
  }

  Future<void> _submitRequest(UserModel user) async {
    setState(() => _isLoading = true);
    try {
      double amount = _selectedPlan == 'monthly' ? priceMonthly : priceQuarterly;
      await _repository.createSubscriptionRequest(
        userId: user.id,
        planType: _selectedPlan!,
        amount: amount,
        proofImage: _proofImage!,
      );
      if (mounted) {
        AppNotifications.showSuccess(context, 'Request submitted! / تم إرسال الطلب');
        setState(() { _selectedPlan = null; _proofImage = null; });
        // Refresh profile to update UI status
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
    final textNavy = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription / الاشتراك', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(user, isActive, isPending, isRejected),
            
            const SizedBox(height: 32),

            if (!isPending) ...[
              Text(isActive ? 'Upgrade Plan / ترقية الاشتراك' : 'Choose a Plan / اختر الباقة', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),

              if (!isActive) _buildPlanTile('Monthly / شهر', '100 EGP', 'monthly'),
              if (!isActive) const SizedBox(height: 12),
              _buildPlanTile('3 Months / ٣ شهور', '250 EGP', 'quarterly', isUpgrade: isActive),
              
              const SizedBox(height: 24),
              
              // Payment Methods
              _buildPaymentInfoCard(),

              const SizedBox(height: 24),
              
              // Upload Area
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

  Widget _buildPlanTile(String title, String price, String value, {bool isUpgrade = false}) {
    final isSelected = _selectedPlan == value;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isSelected ? theme.colorScheme.secondary : Colors.grey.withOpacity(0.1), width: 2)
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? theme.colorScheme.secondary : Colors.grey),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isUpgrade ? 'UPGRADE: $title' : title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(price, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}
