import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _authRepository.hasSession; // Rely on session for initial routing
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _initializeAuth();
    _listenToAuthStateChanges();
  }

  Future<void> _initializeAuth() async {
    // If we have a session, we consider them authenticated for routing purposes
    // We try to fetch the profile in the background
    if (_authRepository.hasSession) {
      await refreshUser();
    }
  }

  void _listenToAuthStateChanges() {
    _authRepository.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        refreshUser();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(
        email: email,
        password: password,
      );
      await refreshUser(); // Fetch profile immediately after login
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    // Avoid multiple simultaneous refreshes if already loading?
    // For now, simple implementation is fine.

    try {
      final user = await _authRepository.getCurrentUserProfile();
      if (user != null) {
        _currentUser = user;
        debugPrint('User profile updated: ${_currentUser?.email}');
        notifyListeners();
      } else {
        // If profile fetch fails but we have session, it might be RLS issue or network.
        // We don't sign them out automatically to avoid annoyance, but UI might show "Guest" or loading.
        debugPrint('User profile fetch returned null.');
      }
    } catch (e) {
      debugPrint('Failed to refresh user profile: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
