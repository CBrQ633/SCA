import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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
        AppNotifications.showSuccess(context, 'تم إرسال الطلب بنجاح! / Request submitted!');
        setState(() {
          _selectedPlan = null;
          _proofImage = null;
        });
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final isPending = user?.subscriptionStatus == 'pending';
    final isActive = user?.isSubscriptionActive ?? false;

    // Specific Emerald Color Code
    const emeraldColor = Color(0xFF10B981);

    if (user?.isAdmin ?? false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 100, showText: true),
              const SizedBox(height: 24),
              const Text('أنت مسئول (Admin)\nلا تحتاج لاشتراك', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () => context.go(AppConstants.routeAdminDashboard), child: const Text('Admin Dashboard')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription / الاشتراك')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isActive ? emeraldColor.withOpacity(0.1) : (isPending ? Colors.orange[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? emeraldColor.withOpacity(0.3) : (isPending ? Colors.orange[200]! : Colors.red[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(isActive ? Icons.verified_user : (isPending ? Icons.timer : Icons.error_outline), color: isActive ? emeraldColor : (isPending ? Colors.orange : Colors.red), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isActive ? 'Account Active / الحساب نشط' : (isPending ? 'Under Review / قيد المراجعة' : 'Subscription Required / مطلوب اشتراك'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(isActive ? 'Expires: ${user?.subscriptionEnd?.toLocal().toString().split(' ')[0]}' : 'Follow steps below / اتبع الخطوات بالأسفل', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (!isActive && !isPending) ...[
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      const Text('Payment Methods / طرق الدفع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(color: Colors.white24, height: 24),
                      _buildPaymentTile(Icons.phone_iphone, 'Vodafone Cash', vodafoneCash, Colors.redAccent),
                      const SizedBox(height: 12),
                      _buildPaymentTile(Icons.account_balance, 'InstaPay', instapay, Colors.greenAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInLeft(child: _buildPlanTile('Monthly / شهر', '100 EGP', 'monthly', theme)),
              const SizedBox(height: 12),
              FadeInRight(child: _buildPlanTile('3 Months / ربع سنوي', '250 EGP', 'quarterly', theme, bestValue: true)),
              const SizedBox(height: 32),
              FadeInUp(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2),
                    ),
                    child: _proofImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_proofImage!, fit: BoxFit.cover))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text('Upload Receipt / ارفع الإيصال', style: TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedPlan == null || _proofImage == null ? null : () => _submitRequest(user!),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REQUEST / إرسال الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ] else if (isPending) ...[
              const SizedBox(height: 40),
              FadeInUp(
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_rounded, size: 80, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('Checking Payment / جاري المراجعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('We will activate your account soon.\nسنقوم بتفعيل حسابك قريباً.', textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(onPressed: () => context.read<AuthProvider>().refreshUser(), icon: const Icon(Icons.refresh), label: const Text('Refresh / تحديث')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          SelectableText(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPlanTile(String title, String price, String value, ThemeData theme, {bool bestValue = false}) {
    final isSelected = _selectedPlan == value;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? theme.colorScheme.secondary : Colors.black.withOpacity(0.05), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? theme.colorScheme.secondary : Colors.grey),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(price, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            if (bestValue) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)), child: const Text('Best Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))),
          ],
        ),
      ),
    );
  }
}
