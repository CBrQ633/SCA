import 'package:flutter/foundation.dart' as foundation;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/config/supabase_config.dart';
import 'user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<UserModel?> getCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final response = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) { return null; }
  }

  // --- LEADERBOARD & TEAM METHODS ---

  Future<List<Map<String, dynamic>>> getGlobalLeaderboard() async {
    try {
      // جلب جميع المستخدمين مع بياناتهم
      final usersResponse = await _supabase.from('profiles').select('id, full_name, sca_id, monthly_target, role').eq('role', 'sales_user');
      final users = usersResponse as List;
      
      List<Map<String, dynamic>> leaderboard = [];

      for (var user in users) {
        // حساب الإنجاز الفعلي لكل مستخدم
        final statsResponse = await _supabase
            .from('call_list_items')
            .select('status')
            .filter('list_id', 'in', 
              _supabase.from('call_lists').select('id').eq('user_id', user['id'])
            );
        
        final items = statsResponse as List;
        int achieved = items.where((i) => i['status'] == 'answered' || i['status'] == 'no_answer').length;
        int target = user['monthly_target'] ?? 0;
        double score = target > 0 ? (achieved / target) : 0.0;

        leaderboard.add({
          'full_name': user['full_name'],
          'sca_id': user['sca_id'],
          'achieved': achieved,
          'target': target,
          'score': score,
        });
      }

      // ترتيب حسب الأعلى تقييماً
      leaderboard.sort((a, b) => b['score'].compareTo(a['score']));
      return leaderboard;
    } catch (e) {
      return [];
    }
  }

  // ... (باقي الدوال كما هي)
  Future<UserModel?> findUserByScaId(String scaId) async {
    final response = await _supabase.from('profiles').select().eq('sca_id', scaId.toUpperCase()).maybeSingle();
    return response != null ? UserModel.fromJson(response) : null;
  }

  Future<void> updateMemberTarget(String memberId, int target) async {
    await _supabase.from('profiles').update({'monthly_target': target}).eq('id', memberId);
  }

  Future<void> addMemberToTeam(String leaderId, String memberId) async {
    await _supabase.from('profiles').update({'leader_id': leaderId}).eq('id', memberId);
  }

  Future<void> sendBroadcast(String leaderId, String content) async {
    await _supabase.from('team_messages').insert({'leader_id': leaderId, 'content': content});
  }

  Future<List<Map<String, dynamic>>> getTeamMessages(String leaderId) async {
    final response = await _supabase.from('team_messages').select().eq('leader_id', leaderId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createPrivateTask({required String leaderId, required String memberId, required String title, String? description}) async {
    await _supabase.from('team_tasks').insert({'leader_id': leaderId, 'member_id': memberId, 'title': title, 'description': description});
  }

  Future<List<Map<String, dynamic>>> getMyTasks(String userId) async {
    final response = await _supabase.from('team_tasks').select().or('member_id.eq.$userId,member_id.is.null').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    await _supabase.from('team_tasks').update({'is_completed': isCompleted}).eq('id', taskId);
  }

  Future<UserModel?> login({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    return await getCurrentUser();
  }

  Future<void> register({required String email, required String password, required String fullName}) async {
    await _supabase.auth.signUp(email: email, password: password, data: {'full_name': fullName});
  }

  Future<List<UserModel>> getMyTeamMembers(String leaderId) async {
    final response = await _supabase.from('profiles').select().eq('leader_id', leaderId);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> logout() async => await _supabase.auth.signOut();
  
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase.from('profiles').select().order('created_at', ascending: false);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq(id, userId);
  }
}
