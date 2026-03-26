import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/models.dart';
import '../../../../core/config/supabase_config.dart';
import 'models/report_stats.dart';

class ReportsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<CallStats> getCallStats(String userId) async {
    try {
      // Fetch only lists belonging to or assigned to this user
      final listsResponse = await _supabase.from('call_lists')
          .select('id')
          .or('user_id.eq.$userId,assigned_to.eq.$userId');
      final listIds = (listsResponse as List).map((l) => l['id']).toList();

      if (listIds.isEmpty) return CallStats(totalCalls: 0, answered: 0, noAnswer: 0, pending: 0);

      final totalResponse = await _supabase.from('call_list_items').count().filter('list_id', 'in', listIds);
      final answeredResponse = await _supabase
          .from('call_list_items')
          .count()
          .filter('list_id', 'in', listIds)
          .eq('status', 'called');
      final noAnswerResponse = await _supabase
          .from('call_list_items')
          .count()
          .filter('list_id', 'in', listIds)
          .eq('status', 'no_answer');
      final pendingResponse = await _supabase
          .from('call_list_items')
          .count()
          .filter('list_id', 'in', listIds)
          .eq('status', 'pending');

      return CallStats(
        totalCalls: totalResponse,
        answered: answeredResponse,
        noAnswer: noAnswerResponse,
        pending: pendingResponse,
      );
    } catch (e) {
      return CallStats(totalCalls: 0, answered: 0, noAnswer: 0, pending: 0);
    }
  }

  Future<SubscriptionStats> getSubscriptionStats() async {
    try {
      final total = await _supabase.from('profiles').count();
      final active = await _supabase.from('profiles').count().eq('subscription_status', 'active');
      final pending = await _supabase.from('profiles').count().eq('subscription_status', 'pending');
      final expired = await _supabase.from('profiles').count().eq('subscription_status', 'expired');

      return SubscriptionStats(totalUsers: total, active: active, pending: pending, expired: expired);
    } catch (e) {
      return SubscriptionStats(totalUsers: 0, active: 0, pending: 0, expired: 0);
    }
  }

  // ✅ Enhanced: Fetch call details with List Name (Filtered for user)
  Future<List<CallEntry>> getCallDetails(String userId) async {
    try {
      final listsResponse = await _supabase.from('call_lists')
          .select('id')
          .or('user_id.eq.$userId,assigned_to.eq.$userId');
      final listIds = (listsResponse as List).map((l) => l['id']).toList();

      if (listIds.isEmpty) return [];

      final response = await _supabase
          .from('call_list_items')
          .select('*, call_lists(name)')
          .filter('list_id', 'in', listIds)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final listData = json['call_lists'] as Map<String, dynamic>?;
        json['list_name'] = listData?['name'] ?? 'Unknown List';
        return CallEntry.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch call details: $e');
    }
  }
}
