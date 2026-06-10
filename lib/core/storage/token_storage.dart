import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _rolesKey = 'auth_roles';

  Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  Future<List<String>> readRoles() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_rolesKey) ?? [];
  }

  Future<void> saveRoles(List<String> roles) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_rolesKey, roles);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_rolesKey);
  }
}
