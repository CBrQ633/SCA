import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
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
  bool get isTeamLeader => _currentUser?.role == 'team_leader';
  bool get isFirstLogin => _isFirstLogin;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _currentUser = await _repository.getCurrentUser();
    if (_currentUser != null && _currentUser!.leaderId != null) {
      // ✅ Automatically subscribe to team notifications
      NotificationService().subscribeToTeam(_currentUser!.leaderId!);
    }
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
        
        if (_currentUser!.leaderId != null) {
          NotificationService().subscribeToTeam(_currentUser!.leaderId!);
        }

        final prefs = await SharedPreferences.getInstance();
        _isFirstLogin = !(prefs.getBool('has_logged_before') ?? false);
        if (_isFirstLogin) await prefs.setBool('has_logged_before', true);
        
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

  Future<bool> joinTeam(String leaderScaId) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.joinTeam(_currentUser!.id, leaderScaId);
      await refreshUser();
      
      // ✅ Subscribe to the new leader's topic
      if (_currentUser?.leaderId != null) {
        NotificationService().subscribeToTeam(_currentUser!.leaderId!);
      }
      
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser?.leaderId != null) {
      NotificationService().unsubscribeFromTeam(_currentUser!.leaderId!);
    }
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _currentUser = await _repository.getCurrentUser();
    notifyListeners();
  }
}
