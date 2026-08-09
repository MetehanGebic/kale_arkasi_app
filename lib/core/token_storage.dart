import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences üzerinden JWT'yi okuma/yazma/silme işlemlerini
/// tek bir yerden yönetir. Böylece token'ın nerede kaydedildiğini
/// bilmek için kod içinde arama yapmak gerekmez.
class TokenStorage {
  static const String _tokenKey = 'jwt_token';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
