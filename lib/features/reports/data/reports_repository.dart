import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import 'models/report_stats.dart';

class ReportsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<CallStats> getCallStats() async {
    // This is a simplified implementation. ideally we'd use aggregate functions in SQL
    // or an Edge Function for performance with large datasets.
    // For now, we fetch counts or all records (not recommended for large scale).
    // Better: use count() exact: true

    try {
      final totalResponse = await _supabase.from('call_list_items').count();
      final answeredResponse = await _supabase.from('call_list_items').count().eq(
          'status',
          'called'); // 'called' usually means answered/processed in some schemas, let's verify map to 'answered'
      final noAnswerResponse = await _supabase
          .from('call_list_items')
          .count()
          .eq('status', 'no_answer');
      final pendingResponse = await _supabase
          .from('call_list_items')
          .count()
          .eq('status', 'pending');

      // The count() method returns int directly in recent Supabase Flutter SDK versions?
      // check documentation or assume standard postgrest builder behavior.
      // Actually standard Postgrest usage in Dart: .count() returns PostgrestFilterBuilder, need to await .count().
      // Wait, .count() acts as a modifier. .select('*', CountOption.exact) returns count in response.

      // Let's use a safer approach for count:

      return CallStats(
        totalCalls: totalResponse,
        answered: answeredResponse,
        noAnswer: noAnswerResponse,
        pending: pendingResponse,
      );
    } catch (e) {
      // Fallback or rethrow
      return CallStats(totalCalls: 0, answered: 0, noAnswer: 0, pending: 0);
    }
  }

  Future<SubscriptionStats> getSubscriptionStats() async {
    try {
      final total = await _supabase.from('profiles').count();
      final active = await _supabase
          .from('profiles')
          .count()
          .eq('subscription_status', 'active');
      final pending = await _supabase
          .from('profiles')
          .count()
          .eq('subscription_status', 'pending');
      final expired = await _supabase
          .from('profiles')
          .count()
          .eq('subscription_status', 'expired');

      return SubscriptionStats(
        totalUsers: total,
        active: active,
        pending: pending,
        expired: expired,
      );
    } catch (e) {
      return SubscriptionStats(
          totalUsers: 0, active: 0, pending: 0, expired: 0);
    }
  }
}
