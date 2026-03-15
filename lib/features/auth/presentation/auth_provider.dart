import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirstLogin = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isFirstLogin => _isFirstLogin;
  
  // ✅ Added missing isAuthenticated getter
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _currentUser = await _repository.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(email: email, password: password);
      if (user != null) {
        _currentUser = user;
        
        final prefs = await SharedPreferences.getInstance();
        _isFirstLogin = !(prefs.getBool('has_logged_before') ?? false);
        if (_isFirstLogin) {
          await prefs.setBool('has_logged_before', true);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({required String email, required String password, required String fullName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.register(email: email, password: password, fullName: fullName);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _currentUser = await _repository.getCurrentUser();
    notifyListeners();
  }
}
