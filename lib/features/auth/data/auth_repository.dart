import 'package:flutter/foundation.dart' as foundation;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/config/supabase_config.dart';
import 'user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        foundation.debugPrint('Profile row not found for user: ${user.id}');
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      foundation.debugPrint('Error fetching profile: $e');
      return null; // Return null instead of throwing to allow fallback logic in login/refresh
    }
  }

  // Register new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (authResponse.user == null) {
        throw Exception('Registration failed');
      }

      // Check if session is null (Email confirmation required)
      if (authResponse.session == null) {
        // Return a placeholder user so AuthProvider knows it succeeded
        // The actual profile will be created by the trigger eventually,
        // but we can't fetch it yet without a session/permissions.
        return UserModel(
          id: authResponse.user!.id,
          email: email,
          fullName: fullName,
          role: 'user',
          subscriptionStatus: 'pending',
          createdAt: DateTime.now(),
        );
      }

      // The trigger will automatically create the user profile
      // Wait a bit for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the created profile
      final profile = await getCurrentUserProfile();
      if (profile == null) {
        // If we have a session but can't get profile, it might be a delay
        // Return a temporary profile based on auth data
        return UserModel(
          id: authResponse.user!.id,
          email: email,
          fullName: fullName,
          role: 'user',
          subscriptionStatus: 'pending',
          createdAt: DateTime.now(),
        );
      }

      return profile;
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Login failed');
      }

      // Generate new session ID
      final sessionId = const Uuid().v4();

      // Save session ID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_session_id', sessionId);

      // Update session ID in database
      try {
        await _supabase.from('users').update({
          'last_session_id': sessionId,
        }).eq('id', authResponse.user!.id);
      } catch (e) {
        foundation.debugPrint('Optional last_session_id update failed: $e');
        // If users table update fails (e.g. user not in table), login should still succeed
        // but single session won't work for this user until synced.
      }

      // Try to update FCM token and other data in background
      _updateFcmTokenInBackground(authResponse.user!.id);

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        // Fallback: Check if user is admin via metadata
        final metadata = authResponse.user!.appMetadata;
        final userMetadata = authResponse.user!.userMetadata;

        final role =
            (metadata['role'] == 'admin' || userMetadata?['role'] == 'admin')
                ? 'admin'
                : 'user';

        foundation
            .debugPrint('Profile missing from DB, using fallback role: $role');

        return UserModel(
          id: authResponse.user!.id,
          email: email,
          fullName: userMetadata?['full_name'],
          role: role,
          subscriptionStatus: role == 'admin' ? 'active' : 'pending',
          createdAt: DateTime.now(),
          lastSessionId: sessionId,
        );
      }

      return profile;
    } catch (e) {
      foundation.debugPrint('Detailed Login error: $e');
      rethrow;
    }
  }

  // Background helper for optional updates
  Future<void> _updateFcmTokenInBackground(String userId) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _supabase.from('users').update({
            'fcm_token': fcmToken,
          }).eq('id', userId);
        }
      }
    } catch (e) {
      foundation.debugPrint('Optional background update skipped: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }

  // Check if session exists
  bool get hasSession => currentUser != null;

  // Stream auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- ADMIN METHODS ---

  // Get all users (Admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Update user profile (Admin only)
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<int> getUsersCount() async {
    final response = await _supabase.from('users').select('id');
    return (response as List).length;
  }

  // Delete user (Admin only)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.rpc('delete_user_v2', params: {'target_user_id': userId});
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
