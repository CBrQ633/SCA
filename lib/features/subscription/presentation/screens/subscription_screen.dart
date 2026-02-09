import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
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
  String? _selectedPlan; // 'monthly' or 'quarterly'
  File? _proofImage;

  // Prices
  static const double priceMonthly = 100.0;
  static const double priceQuarterly = 250.0;

  // Payment Numbers
  static const String vodafoneCash = '01080305645';
  static const String instapay = '01550381486';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest(UserModel user) async {
    setState(() => _isLoading = true);

    try {
      double amount =
          _selectedPlan == 'monthly' ? priceMonthly : priceQuarterly;

      await _repository.createSubscriptionRequest(
        userId: user.id,
        planType: _selectedPlan!,
        amount: amount,
        proofImage: _proofImage!,
      );

      if (mounted) {
        AppNotifications.showSuccess(
          context,
          'تم إرسال الطلب بنجاح! في انتظار الموافقة\n\nRequest submitted! Waiting for approval',
        );
        setState(() {
          _selectedPlan = null;
          _proofImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isPending = user?.subscriptionStatus == 'pending';
    final isActive = user?.isSubscriptionActive ?? false;

    // ADMIN BYPASS: If the user is an admin, they shouldn't be here
    if (user?.isAdmin ?? false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access / وصول الأدمن')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 100, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'أنت مسئول (Admin)\nلا تحتاج لاشتراك',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.routeAdminDashboard),
                child: const Text('Go to Dashboard / الذهاب للوحة التحكم'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription / الاشتراك')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Status Card
            Card(
              color: isActive
                  ? Colors.green[100]
                  : (isPending ? Colors.orange[100] : Colors.red[100]),
              child: ListTile(
                leading: Icon(
                  isActive
                      ? Icons.check_circle
                      : (isPending ? Icons.hourglass_bottom : Icons.error),
                  color: isActive
                      ? Colors.green
                      : (isPending ? Colors.orange : Colors.red),
                  size: 40,
                ),
                title: Text(
                  isActive
                      ? 'Subscription Active / الاشتراك نشط'
                      : (isPending
                          ? 'Request Pending / في انتظار الموافقة'
                          : 'Subscription Inactive / الاشتراك غير نشط'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: isActive
                    ? Text(
                        'Expires on: ${user?.subscriptionEnd?.toLocal().toString().split(' ')[0]}')
                    : (isPending
                        ? const Text('Your payment is being reviewed.')
                        : const Text(
                            'Please subscribe to continue using the app.')),
              ),
            ),
            const SizedBox(height: 24),

            // === PENDING STATE ===
            if (isPending) ...[
              const SizedBox(height: 40),
              const Icon(Icons.hourglass_bottom,
                  size: 100, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'في انتظار التفعيل',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<AuthProvider>().refreshUser(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status / تحديث الحالة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            // === INACTIVE STATE (Payment Form) ===
            if (!isActive && !isPending) ...[
              // Payment Info Card
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طرق الدفع / Payment Methods',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone_android,
                              color: Colors.red, size: 28),
                          SizedBox(width: 8),
                          Text('Vodafone Cash: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SelectableText(vodafoneCash,
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.green, size: 28),
                          SizedBox(width: 8),
                          Text('InstaPay: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SelectableText(instapay,
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'اختر الباقة / Select a Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Plan Selection
              _buildPlanCard(
                title: 'شهر واحد / Monthly Plan',
                price: '$priceMonthly جنيه / EGP',
                value: 'monthly',
              ),
              _buildPlanCard(
                title: '3 شهور / Quarterly Plan',
                price: '$priceQuarterly جنيه / EGP',
                value: 'quarterly',
                isBestValue: true,
              ),

              const SizedBox(height: 24),
              const Text(
                'إيصال الدفع / Payment Proof',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Image Upload Area
              const Text(
                'الرجاء الضغط على المربع أدناه لرفع صورة الإيصال\nPlease tap the box below to upload payment proof',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180, // Increased height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _proofImage == null
                        ? Colors.blue.withValues(alpha: 0.05)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _proofImage == null ? Colors.blue : Colors.grey,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _proofImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_proofImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 50, color: Colors.blue[700]),
                            const SizedBox(height: 12),
                            Text(
                              'اضغط هنا لرفع صورة التحويل\nTap here to upload transfer receipt',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Validation Message if button is disabled
              if (_selectedPlan == null || _proofImage == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _selectedPlan == null
                        ? '⚠️ يرجى اختيار باقة أولاً (Select a plan)'
                        : '⚠️ يرجى رفع صورة الإيصال (Upload proof)',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading || user == null
                      ? null
                      : () {
                          if (_selectedPlan == null || _proofImage == null) {
                            AppNotifications.showError(
                              context,
                              'يرجى اختيار باقة ورفع صورة الإيصال أولاً\nPlease select a plan and upload proof image',
                            );
                            return;
                          }
                          _submitRequest(user);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال طلب التفعيل / Send Activation Request',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String value,
    bool isBestValue = false,
  }) {
    final isSelected = _selectedPlan == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = value),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(price),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.black)
                  : const Icon(Icons.circle_outlined),
            ),
            if (isBestValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
