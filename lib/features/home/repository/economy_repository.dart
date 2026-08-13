import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/api_constants.dart';

class EconomyRepository {
  final Dio _dio;
  final String baseUrl = ApiConstants.economyUrl;

  EconomyRepository({Dio? dio}) : _dio = dio ?? DioClient.getDio() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<Map<String, dynamic>> claimDailyTea(String token) async {
    try {
      final response = await _dio.post(
        '$baseUrl/daily-tea',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']; // { message, reward, newBalance, lastDailyTeaClaimAt }
      }
      throw Exception(data['message'] ?? 'Çay alınırken bir hata oluştu.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Çay alınırken bir hata oluştu.',
      );
    }
  }

  // Uygulama açılışında (veya HomeScreen her göründüğünde) mevcut bakiyeyi
  // sunucudan çekmek için. Bakiyeyi DEĞİŞTİRMEZ, sadece okur.
  Future<Map<String, dynamic>> getBalance(String token) async {
    try {
      final response = await _dio.get(
        '$baseUrl/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']; // { teaBalance, lastDailyTeaClaimAt }
      }
      throw Exception(data['message'] ?? 'Bakiye alınamadı.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Bakiye alınamadı.');
    }
  }
}
