import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';
import '../../../core/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isTeamLeader => _currentUser?.role == 'team_leader';
  bool get isFirstLogin => _currentUser?.fullName == null;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(email: email, password: password);
      _currentUser = user;
      _isLoading = false;
      
      final currentLid = _currentUser?.leaderId;
      if (currentLid != null) {
        NotificationService().subscribeToTeam(currentLid);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
      await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinTeam(String leaderId) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null; 
    notifyListeners();
    try {
      await _repository.joinTeam(_currentUser!.id, leaderId);
      await refreshUser();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> getUsersCount() async {
    return await _repository.getUsersCount();
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
