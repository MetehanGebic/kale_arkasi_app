import 'package:dio/dio.dart';
import '../../../core/api_constants.dart';
import '../../../core/token_storage.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final String _baseUrl = ApiConstants.identityUrl;

  AuthRepository({TokenStorage? tokenStorage})
    : _dio = Dio(),
      _tokenStorage = tokenStorage ?? TokenStorage() {
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
      // Dio, 2xx dışı durum kodlarında zaten DioException fırlatır;
      // buraya normalde düşülmez ama beklenmedik bir durum için yine de ele alıyoruz.
      throw Exception('Takımlar alınamadı.');
    } on DioException catch (e) {
      // Kendi attığımız Exception'ı burada YAKALAMIYORUZ (o zaten DioException değil),
      // böylece "Bağlantı hatası: Exception: ..." gibi iç içe/çift mesaj oluşmuyor.
      throw Exception(
        e.response?.data?['message'] ??
            'Bağlantı hatası: Sunucuya ulaşılamadı.',
      );
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
        final token = response.data['data']['token'];
        final Map<String, dynamic> user = response.data['data']['user'];

        // Token'ı user map'inin içine dahil ediyoruz ki UI/Cubit erişebilsin
        user['token'] = token;

        await _tokenStorage.saveToken(token);
        return user;
      }
      throw Exception(response.data['message'] ?? 'Kayıt başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Sunucu ile iletişim kurulamadı.',
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
        final token = response.data['data']['token'];
        final Map<String, dynamic> user = response.data['data']['user'];

        // Token'ı user map'inin içine dahil ediyoruz ki UI/Cubit erişebilsin
        user['token'] = token;

        await _tokenStorage.saveToken(token);
        return user;
      }
      throw Exception(response.data['message'] ?? 'Giriş başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Sunucu ile iletişim kurulamadı.',
      );
    }
  }

  // Şifremi Unuttum
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/forgot-password',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'E-posta gönderildi.';
      }
      throw Exception('İşlem başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Sunucu ile iletişim kurulamadı.',
      );
    }
  }

  // Şifre Sıfırlama
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/reset-password',
        data: {
          'email': email,
          'code': code,
          'password': newPassword,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Şifre başarıyla güncellendi.';
      }
      throw Exception('İşlem başarısız.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Sunucu ile iletişim kurulamadı.',
      );
    }
  }

  /// Uygulama açılışında kayıtlı token var mı diye bakmak için.
  Future<String?> getStoredToken() => _tokenStorage.getToken();

  /// Çıkış yapıldığında token'ı cihazdan temizler.
  Future<void> logout() => _tokenStorage.clearToken();
}
