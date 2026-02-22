import 'dart:async';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
  bool get isAuthenticated => _authRepository.hasSession;
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
      refreshUser();
    }
  }

  void _startSessionCheckTimer() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isAuthenticated) {
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
    if (_authRepository.hasSession) {
      await refreshUser();
    }
  }

  void _listenToAuthStateChanges() {
    _authRepository.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        refreshUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('sca_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('sca_device_id', deviceId);
    }
    return deviceId;
  }

  // Added missing register method
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
      final user = await _authRepository.login(email: email, password: password);
      final deviceId = await _getOrCreateDeviceId();

      await _authRepository.updateUserDeviceId(user.id, deviceId);

      await refreshUser();
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

  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUserProfile();
      if (user != null) {
        final localDeviceId = await _getOrCreateDeviceId();

        if (user.currentDeviceId != null && user.currentDeviceId != localDeviceId) {
          foundation.debugPrint('Security: Unauthorized device detected. Logging out.');
          _errorMessage = 'تم تسجيل الدخول من جهاز آخر. (Logged in from another device)';
          notifyListeners();
          await logout();
          return;
        }

        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      foundation.debugPrint('Session Refresh Error: $e');
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
