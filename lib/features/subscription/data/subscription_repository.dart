import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new subscription request
  Future<void> createSubscriptionRequest({
    required String userId,
    required String planType,
    required double amount,
    required File proofImage,
  }) async {
    try {
      // 1. Upload Image with error handling
      final fileExt = proofImage.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';

      String publicUrl;
      try {
        // Try to upload to Supabase Storage
        await _supabase.storage.from('payment_proofs').upload(
              fileName,
              proofImage,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

        // Get Public URL
        publicUrl =
            _supabase.storage.from('payment_proofs').getPublicUrl(fileName);
      } catch (storageError) {
        // If bucket doesn't exist, store placeholder
        // NOTE: Admin should create 'payment_proofs' bucket in Supabase Storage first
        publicUrl = 'pending_upload_$fileName';
        debugPrint(
            'Storage upload failed - bucket may not exist: $storageError');
      }

      // 2. Insert Request Record
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

  // Get all pending requests (Admin only)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('subscription_requests')
          .select(
              '*, users!user_id(email, full_name)') // Fix: explicit relationship
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('column') &&
          e.message.contains('does not exist')) {
        throw Exception(
            'خطأ في قاعدة البيانات: بعض الأعمدة مفقودة. يرجى تنفيذ أكواد SQL المحدثة في Supabase.\n(Missing database columns: ${e.message})');
      }
      throw Exception('خطأ في جلب الطلبات: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  // Get count of pending requests (for badges)
  Future<int> getPendingCount() async {
    try {
      final response = await _supabase
          .from('subscription_requests')
          .select('id')
          .eq('status', 'pending');
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }

  // Approve a request (Admin only)
  Future<void> approveRequest(
      String requestId, String userId, String planType) async {
    try {
      final now = DateTime.now();
      DateTime endDate;

      if (planType == 'monthly') {
        endDate = now.add(const Duration(days: 30));
      } else if (planType == 'quarterly') {
        endDate = now.add(const Duration(days: 90));
      } else {
        endDate = now.add(const Duration(days: 30)); // Default
      }

      // 1. Update Request Status
      await _supabase
          .from('subscription_requests')
          .update({'status': 'approved'}).eq('id', requestId);

      // 2. Update User Subscription
      await _supabase.from('users').update({
        'subscription_status': 'active',
        'subscription_start': now.toIso8601String(),
        'subscription_end': endDate.toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  // Reject a request (Admin only)
  Future<void> rejectRequest(String requestId) async {
    try {
      await _supabase
          .from('subscription_requests')
          .update({'status': 'rejected'}).eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }
}
