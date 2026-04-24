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

  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<String?> getRole() => _storage.read(key: _keyRole);
  static Future<String?> getUsername() => _storage.read(key: _keyUsername);
  static Future<String?> getFirstName() => _storage.read(key: _keyFirstName);
  static Future<String?> getLastName() => _storage.read(key: _keyLastName);

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }
}
