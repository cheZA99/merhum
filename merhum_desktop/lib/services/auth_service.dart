import 'package:shared_preferences/shared_preferences.dart';

// Using shared_preferences instead of flutter_secure_storage — more reliable on Windows
class AuthService {
  static const _keyToken = 'token';
  static const _keyRole = 'role';
  static const _keyIme = 'ime';
  static const _keyPrezime = 'prezime';

  Future<void> saveSession({
    required String token,
    required String role,
    required String ime,
    required String prezime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyIme, ime);
    await prefs.setString(_keyPrezime, prezime);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyIme);
    await prefs.remove(_keyPrezime);
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

  Future<String?> getIme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIme);
  }

  Future<String?> getPrezime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrezime);
  }
}
