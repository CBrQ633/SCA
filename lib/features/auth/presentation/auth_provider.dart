import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

class AuthProvider with ChangeNotifier, WidgetsBindingObserver {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _sessionCheckTimer;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _authRepository.hasSession; // Rely on session for initial routing
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _initializeAuth();
    _listenToAuthStateChanges();
    WidgetsBinding.instance.addObserver(this);
    _startSessionCheckTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, refreshing user to check session...');
      refreshUser();
    }
  }

  void _startSessionCheckTimer() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (isAuthenticated) {
        debugPrint('Periodic session check...');
        refreshUser();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionCheckTimer?.cancel();
    super.dispose();
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
        // Check Session ID
        final prefs = await SharedPreferences.getInstance();
        final localSessionId = prefs.getString('last_session_id');

        if (user.lastSessionId != null &&
            localSessionId != user.lastSessionId) {
          // Session mismatch! Logout.
          debugPrint(
              'Session mismatch: Local=$localSessionId, Remote=${user.lastSessionId}');
          _errorMessage =
              'تم تسجيل الدخول من جهاز آخر. (Logged in from another device)';
          await logout();
          return;
        }

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
