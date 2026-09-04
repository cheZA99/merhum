import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyRole = 'user_role';
  static const _keyUsername = 'username';
  static const _keyFirstName = 'first_name';
  static const _keyLastName = 'last_name';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await ApiService.post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _storage.write(key: _keyToken, value: data['token'] as String?);
    await _storage.write(key: _keyRole, value: data['role'] as String?);
    await _storage.write(key: _keyUsername, value: data['username'] as String?);
    await _storage.write(key: _keyFirstName, value: data['firstName'] as String?);
    await _storage.write(key: _keyLastName, value: data['lastName'] as String?);
    return data;
  }

  static Future<void> register(Map<String, dynamic> body) async {
    await ApiService.post('/api/auth/register', body);
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiService.post('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiService.get('/api/auth/me');
    return res.data as Map<String, dynamic>;
  }

  static Future<void> updateProfile(Map<String, dynamic> body) async {
    await ApiService.put('/api/auth/me', body);
    await _storage.write(key: _keyFirstName, value: body['firstName'] as String?);
    await _storage.write(key: _keyLastName, value: body['lastName'] as String?);
  }

  static Future<String?> uploadProfilePhoto(String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    final res = await ApiService.dio.post('/api/auth/me/photo', data: form);
    final body = res.data as Map<String, dynamic>;
    return body['photoUrl'] as String?;
  }

  static Future<void> forgotPassword(String email) async {
    await ApiService.post('/api/auth/forgot-password', {'email': email});
  }

  static Future<void> resetPassword(String email, String token, String newPassword) async {
    await ApiService.post('/api/auth/reset-password', {
      'email': email,
      'token': token,
      'newPassword': newPassword,
    });
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<String?> getRole() => _storage.read(key: _keyRole);
  static Future<String?> getUsername() => _storage.read(key: _keyUsername);
  static Future<String?> getFirstName() => _storage.read(key: _keyFirstName);
  static Future<String?> getLastName() => _storage.read(key: _keyLastName);

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null || token.isEmpty) return false;
    return !_isTokenExpired(token);
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = claims['exp'] as int?;
      if (exp == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
