import 'package:shared_preferences/shared_preferences.dart';

// Using shared_preferences instead of flutter_secure_storage — more reliable on Windows
class AuthService {
  static const _keyToken = 'token';
  static const _keyRole = 'role';
  static const _keyFirstName = 'firstName';
  static const _keyLastName = 'lastName';

  Future<void> saveSession({
    required String token,
    required String role,
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFirstName);
  }

  Future<String?> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastName);
  }
}
