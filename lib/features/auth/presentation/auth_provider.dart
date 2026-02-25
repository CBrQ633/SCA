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
  
  // Removed the periodic timer that caused redirects/lag

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authRepository.hasSession;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _initializeAuth();
    _listenToAuthStateChanges();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only refresh when the user returns to the app to check session validity
    if (state == AppLifecycleState.resumed && isAuthenticated) {
      refreshUser(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    if (_authRepository.hasSession) {
      await refreshUser(silent: true);
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

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "حدث خطأ غير متوقع أثناء التسجيل";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    if (_isLoading) return false;
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(email: email, password: password);
      final deviceId = await _getOrCreateDeviceId();
      await _authRepository.updateUserDeviceId(user.id, deviceId);
      
      await refreshUser();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "بيانات الدخول غير صحيحة أو الحساب غير موجود";
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshUser({bool silent = false}) async {
    try {
      final user = await _authRepository.getCurrentUserProfile();
      if (user != null) {
        final localDeviceId = await _getOrCreateDeviceId();
        
        if (user.currentDeviceId != null && user.currentDeviceId != localDeviceId) {
          _errorMessage = 'تم تسجيل الدخول من جهاز آخر';
          if (!silent) notifyListeners();
          await logout();
          return;
        }

        _currentUser = user;
        if (!silent) notifyListeners();
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return "البريد الإلكتروني أو كلمة المرور غير صحيحة";
    } else if (message.contains('Email not confirmed')) {
      return "يرجى تأكيد البريد الإلكتروني أولاً";
    } else if (message.contains('User already registered')) {
      return "هذا البريد مسجل بالفعل، يمكنك تسجيل الدخول";
    } else if (message.contains('Password should be')) {
      return "كلمة المرور ضعيفة جداً";
    }
    return "فشل في العملية: $message";
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
