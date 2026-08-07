import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio _dio;
  // Android emülatörler localhost (127.0.0.1) yerine 10.0.2.2 kullanır.
  // Gerçek cihaz kullanıyorsan buraya bilgisayarının yerel IP adresini yazmalısın.
  final String _baseUrl = 'http://10.0.2.2:3000/api/identity';

  AuthRepository() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // API'den gelen takımları UI'da listelemek için
  Future<List<dynamic>> getClubs() async {
    try {
      final response = await _dio.get('$_baseUrl/clubs');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Takımlar alınamadı.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Kullanıcı Kaydı
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String favoriteClubId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'favoriteClubId': favoriteClubId,
        },
      );

      if (response.statusCode == 201) {
        await _saveToken(response.data['data']['token']);
        return response.data['data']['user'];
      }
      throw Exception(response.data['message'] ?? 'Kayıt başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Sunucu ile iletişim kurulamadı.',
      );
    }
  }

  // Kullanıcı Girişi
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        await _saveToken(response.data['data']['token']);
        return response.data['data']['user'];
      }
      throw Exception(response.data['message'] ?? 'Giriş başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Sunucu ile iletişim kurulamadı.',
      );
    }
  }

  // Token'ı Cihaz Hafızasına (SharedPreferences) Kaydetme
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }
}
