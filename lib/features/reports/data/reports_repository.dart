import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/models.dart';
import '../../../../core/config/supabase_config.dart';
import 'models/report_stats.dart';

class ReportsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<CallStats> getCallStats() async {
    try {
      final totalResponse = await _supabase.from('call_list_items').count();
      final answeredResponse = await _supabase
          .from('call_list_items')
          .count()
          .eq('status', 'called');
      final noAnswerResponse = await _supabase
          .from('call_list_items')
          .count()
          .eq('status', 'no_answer');
      final pendingResponse = await _supabase
          .from('call_list_items')
          .count()
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

  // ✅ Enhanced: Fetch call details with List Name
  Future<List<CallEntry>> getCallDetails() async {
    try {
      final response = await _supabase
          .from('call_list_items')
          .select('*, call_lists(name)') // Join with call_lists to get the name
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Flatten the joined data for the CallEntry model
        final listData = json['call_lists'] as Map<String, dynamic>?;
        json['list_name'] = listData?['name'] ?? 'Unknown List';
        return CallEntry.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch call details: $e');
    }
  }
}
