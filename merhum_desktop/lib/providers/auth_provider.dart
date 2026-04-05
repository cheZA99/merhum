import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;

  bool isLoggedIn = false;
  String? role;
  String? ime;
  bool isLoading = false;

  AuthProvider({required AuthService authService, required ApiService apiService})
      : _authService = authService,
        _apiService = apiService;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });

      final data = response.data;
      final token = data['data']?['token'] ?? data['token'];
      final userRole = data['data']?['role'] ?? data['role'] ?? 'Admin';
      final firstName = data['data']?['firstName'] ?? data['data']?['ime'] ?? data['ime'] ?? username;
      final lastName = data['data']?['lastName'] ?? data['data']?['prezime'] ?? data['prezime'] ?? '';

      await _authService.saveSession(
        token: token,
        role: userRole,
        ime: firstName,
        prezime: lastName,
      );

      isLoggedIn = true;
      role = userRole;
      ime = firstName;
      return true;
    } on DioException catch (e) {
      debugPrint('LOGIN ERROR: ${e.type} | ${e.message} | ${e.response?.statusCode} | ${e.response?.data}');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    isLoggedIn = false;
    role = null;
    ime = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      role = await _authService.getRole();
      ime = await _authService.getIme();
    }
    notifyListeners();
  }
}
