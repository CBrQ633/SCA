import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createSubscriptionRequest({
    required String userId,
    required String planType,
    required double amount,
    required File proofImage,
  }) async {
    try {
      final fileExt = proofImage.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';

      String publicUrl;
      try {
        final storagePath = 'proofs/$fileName';
        await _supabase.storage
            .from('payment_proofs')
            .upload(storagePath, proofImage);
        publicUrl =
            _supabase.storage.from('payment_proofs').getPublicUrl(storagePath);
      } catch (e) {
        throw Exception('فشل في رفع صورة الإيصال، تأكد من اتصال الإنترنت');
      }

      await _supabase.from('subscription_requests').insert({
        'user_id': userId,
        'plan_type': planType,
        'amount': amount,
        'payment_screenshot_url': publicUrl,
        'status': 'pending',
      });

      await _supabase.from('profiles').update({
        'subscription_status': 'pending',
        'subscription_reject_reason': null
      }).eq('id', userId);
    } catch (e) {
      throw Exception('حدث خطأ أثناء إرسال الطلب: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('subscription_requests')
          .select('*, profiles!user_id(email, full_name, fcm_token)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<int> getPendingCount() async {
    try {
      final response = await _supabase
          .from('subscription_requests')
          .select('id')
          .eq('status', 'pending');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> approveRequest(
      String requestId, String userId, String planType) async {
    try {
      final now = DateTime.now();
      DateTime endDate = planType == 'quarterly'
          ? now.add(const Duration(days: 90))
          : now.add(const Duration(days: 30));

      await _supabase
          .from('subscription_requests')
          .update({'status': 'approved'}).eq('id', requestId);

      await _supabase.from('profiles').update({
        'subscription_status': 'active',
        'subscription_reject_reason': null,
        'subscription_start': now.toIso8601String(),
        'subscription_end': endDate.toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('فشل في تفعيل الاشتراك: $e');
    }
  }

  Future<void> rejectRequest(String requestId, String userId,
      {String? reason}) async {
    try {
      // 1. Update request status
      await _supabase.from('subscription_requests').update({
        'status': 'rejected',
        'reject_reason': reason,
      }).eq('id', requestId);

      // 2. Update user profile status
      await _supabase.from('profiles').update({
        'subscription_status': 'rejected',
        'subscription_reject_reason': reason
      }).eq('id', userId);
    } catch (e) {
      throw Exception('فشل في رفض الطلب: $e');
    }
  }
}
