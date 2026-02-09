import 'package:supabase_flutter/supabase_flutter.dart';
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
      final response =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
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

      // The trigger will automatically create the user profile
      // Wait a bit for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the created profile
      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Failed to create user profile');
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

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Failed to fetch user profile');
      }

      return profile;
    } on AuthException catch (e) {
      // Specific Supabase Auth errors
      String message;
      if (e.message.contains('Invalid login credentials')) {
        message =
            'البريد الإلكتروني أو كلمة المرور غير صحيحة (Invalid credentials)';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'يرجى تأكيد البريد الإلكتروني أولاً (Email not confirmed)';
      } else {
        message = 'خطأ في تسجيل الدخول: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Login error: $e');
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
}
