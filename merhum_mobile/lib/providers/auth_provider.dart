import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _role = '';
  String _username = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String get role => _role;
  String get username => _username;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName'.trim();
  bool get isLoading => _isLoading;
  bool get isPorodica => _role == 'Porodica';
  bool get isImam => _role == 'Imam';
  bool get isFuneralHome => _role == 'PogrebnoPreduzeće';

  Future<void> checkAuthStatus() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      _role = await AuthService.getRole() ?? '';
      _username = await AuthService.getUsername() ?? '';
      _firstName = await AuthService.getFirstName() ?? '';
      _lastName = await AuthService.getLastName() ?? '';
    }
    notifyListeners();
  }

  Future<String> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await AuthService.login(username, password);
      _isLoggedIn = true;
      _role = data['role'] as String? ?? '';
      _username = data['username'] as String? ?? '';
      _firstName = data['firstName'] as String? ?? '';
      _lastName = data['lastName'] as String? ?? '';
      return _role;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      await AuthService.changePassword(currentPassword, newPassword);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Greška pri promjeni lozinke.';
    } catch (_) {
      return 'Greška pri promjeni lozinke.';
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isLoggedIn = false;
    _role = '';
    _username = '';
    _firstName = '';
    _lastName = '';
    notifyListeners();
  }
}
