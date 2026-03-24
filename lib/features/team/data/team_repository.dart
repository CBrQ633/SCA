import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/user_model.dart';

class TeamRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all members assigned to a specific leader
  Future<List<UserModel>> getTeamMembers(String leaderId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('leader_id', leaderId)
          .order('full_name', ascending: true);
      
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  /// Add a member to the team using their SCA ID
  Future<void> addMemberByScaId(String leaderId, String scaId) async {
    try {
      // 1. Find user by scaId
      final userResponse = await _supabase
          .from('profiles')
          .select('id, leader_id')
          .eq('sca_id', scaId.toUpperCase())
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User with ID $scaId not found / لم يتم العثور على المستخدم');
      }

      if (userResponse['leader_id'] != null) {
        throw Exception('User is already in another team / المستخدم عضو في فريق آخر بالفعل');
      }

      if (userResponse['id'] == leaderId) {
        throw Exception('You cannot add yourself to your team / لا يمكنك إضافة نفسك لفريقك');
      }

      // 2. Assign leader_id
      await _supabase
          .from('profiles')
          .update({'leader_id': leaderId})
          .eq('id', userResponse['id']);
          
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a member from the team
  Future<void> removeMember(String memberId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'leader_id': null})
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }
}
