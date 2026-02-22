import 'package:flutter/foundation.dart' as foundation;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/config/supabase_config.dart';
import 'user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final response = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      foundation.debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (authResponse.user == null) throw Exception('Login failed');

      final profile = await getCurrentUserProfile();
      if (profile == null) throw Exception('Profile not found');

      _updateFcmTokenInBackground(authResponse.user!.id);
      return profile;
    } catch (e) {
      foundation.debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> updateUserDeviceId(String userId, String deviceId) async {
    try {
      await _supabase.from('profiles').update({'current_device_id': deviceId}).eq('id', userId);
    } catch (e) {
      foundation.debugPrint('Failed to update device ID: $e');
    }
  }

  Future<UserModel> register({required String email, required String password, required String fullName}) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}
      );
      if (authResponse.user == null) throw Exception('Registration failed');

      return UserModel(
        id: authResponse.user!.id,
        email: email,
        fullName: fullName,
        role: 'sales_user',
        subscriptionStatus: 'active',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<void> _updateFcmTokenInBackground(String userId) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _supabase.from('profiles').update({'fcm_token': fcmToken}).eq('id', userId);
        }
      }
    } catch (e) {}
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  bool get hasSession => currentUser != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- ADMIN METHODS ---

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase.from('profiles').select().order('created_at', ascending: false);
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Deleting from profiles will cascade if configured,
      // but ideally you delete from auth.users via a service role or edge function.
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<int> getUsersCount() async {
    try {
      final response = await _supabase.from('profiles').select('id');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
