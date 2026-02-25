import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
import 'package:smart_call_assistant/features/auth/data/user_model.dart';
import 'package:smart_call_assistant/core/utils/app_notifications.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/features/subscription/data/subscription_repository.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

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
            // Status Card
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textNavy, fontSize: 16),
                      ),
                    ],
                  ),
                  if (isActive && user?.subscriptionEnd != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Expires on: ${DateFormat('yyyy-MM-dd').format(user!.subscriptionEnd!)}',
                      style: TextStyle(color: textNavy.withOpacity(0.7), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'ينتهي في: ${DateFormat('yyyy-MM-dd').format(user.subscriptionEnd!)}',
                      style: TextStyle(color: textNavy.withOpacity(0.7), fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Renew or Upgrade / تجديد أو ترقية', style: TextStyle(fontWeight: FontWeight.bold, color: textNavy, fontSize: 15)),
            const SizedBox(height: 16),

            if (!isPending) ...[
              // Payment Info
              _buildSectionCard([
                _buildPaymentRow('Vodafone Cash', vodafoneCash, Colors.red),
                const Divider(),
                _buildPaymentRow('InstaPay', instapay, Colors.green),
              ]),
              const SizedBox(height: 24),
              
              // Plans
              _buildPlanTile('Monthly / شهر', '100 EGP', 'monthly'),
              const SizedBox(height: 12),
              _buildPlanTile('3 Months / ٣ شهور', '250 EGP', 'quarterly'),
              
              const SizedBox(height: 24),
              
              // Upload Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid)),
                  child: _proofImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_proofImage!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 40, color: textNavy), Text('Upload Receipt / ارفع الإيصال', style: TextStyle(color: textNavy, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedPlan == null || _proofImage == null ? null : () => _submitRequest(user!),
                  style: ElevatedButton.styleFrom(backgroundColor: textNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT / إرسال الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('Your request is being processed...', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('جاري معالجة طلبك حالياً', textAlign: TextAlign.center),
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

  Widget _buildSectionCard(List<Widget> children) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: children));
  }

  Widget _buildPaymentRow(String label, String value, Color color) {
    return ListTile(
      leading: Icon(Icons.payment, color: color),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
      trailing: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildPlanTile(String title, String price, String value) {
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(price, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}
