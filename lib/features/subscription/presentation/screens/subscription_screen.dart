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
    const textNavy = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Subscription / الاشتراك', style: TextStyle(color: textNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFD1FAE5) : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? const Color(0xFF10B981) : (isPending ? Colors.amber : Colors.redAccent)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isActive ? Icons.verified : (isPending ? Icons.timer : Icons.error_outline), color: isActive ? Colors.green : (isPending ? Colors.orange : Colors.red)),
                      const SizedBox(width: 12),
                      Text(
                        isActive ? 'Account Active / الحساب نشط' : (isPending ? 'Pending Review / قيد المراجعة' : 'Inactive / غير نشط'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textNavy),
                      ),
                    ],
                  ),
                  if (isActive && user?.subscriptionEnd != null) ...[
                    const SizedBox(height: 8),
                    Text('Expires: ${DateFormat('yyyy-MM-dd').format(user!.subscriptionEnd!)}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(isActive ? 'Upgrade Plan / ترقية الاشتراك' : 'Choose a Plan / اختر الباقة', style: const TextStyle(fontWeight: FontWeight.bold, color: textNavy, fontSize: 15)),
            const SizedBox(height: 16),

            if (!isPending) ...[
              // If NOT active, show both. If active, ONLY show Quarterly (Upgrade).
              if (!isActive) _buildPlanTile('Monthly / شهر', '100 EGP', 'monthly'),
              if (!isActive) const SizedBox(height: 12),
              _buildPlanTile('3 Months / ٣ شهور', '250 EGP', 'quarterly', isUpgrade: isActive),
              
              const SizedBox(height: 24),
              
              // Payment Methods
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _buildPaymentRow('Vodafone Cash', vodafoneCash, Colors.red),
                    const Divider(),
                    _buildPaymentRow('InstaPay', instapay, Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Upload Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300, width: 2)),
                  child: _proofImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_proofImage!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file, size: 32, color: textNavy), Text('Upload Receipt / ارفع الإيصال', style: TextStyle(color: textNavy, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedPlan == null || _proofImage == null ? null : () => _submitRequest(user!),
                  style: ElevatedButton.styleFrom(backgroundColor: textNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REQUEST / إرسال الطلب'),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Your request is being reviewed...\nجاري مراجعة طلبك...', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, Color color) {
    return ListTile(
      leading: Icon(Icons.payment, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildPlanTile(String title, String price, String value, {bool isUpgrade = false}) {
    final isSelected = _selectedPlan == value;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.transparent, width: 2)),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF10B981) : Colors.grey),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isUpgrade ? 'UPGRADE: $title' : title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(price, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}
