import 'dart:io';
import 'package:flutter/foundation.dart';
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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';

      String publicUrl;
      try {
        await _supabase.storage.from('payment_proofs').upload(
              fileName,
              proofImage,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
        publicUrl = _supabase.storage.from('payment_proofs').getPublicUrl(fileName);
      } catch (storageError) {
        publicUrl = 'pending_upload_$fileName';
        debugPrint('Storage upload failed: $storageError');
      }

      await _supabase.from('subscription_requests').insert({
        'user_id': userId,
        'plan_type': planType,
        'amount': amount,
        'payment_screenshot_url': publicUrl,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to create subscription request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('subscription_requests')
          .select('*, profiles!user_id(email, full_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
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

  Future<void> approveRequest(String requestId, String userId, String planType) async {
    try {
      final now = DateTime.now();
      DateTime endDate = planType == 'quarterly'
          ? now.add(const Duration(days: 90))
          : now.add(const Duration(days: 30));

      await _supabase.from('subscription_requests').update({'status': 'approved'}).eq('id', requestId);

      await _supabase.from('profiles').update({
        'subscription_status': 'active',
        'subscription_start': now.toIso8601String(),
        'subscription_end': endDate.toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _supabase.from('subscription_requests').update({'status': 'rejected'}).eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }
}
