import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/api_constants.dart';

class AdminRepository {
  final Dio _dio;
  final String baseUrl = ApiConstants.baseUrl; // Veya ilgili base url, şimdilik /api kullanabiliriz. Eğer yoksa hardcode.

  AdminRepository({Dio? dio}) : _dio = dio ?? DioClient.getDio() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<List<Map<String, dynamic>>> getTrackedMatches(String token) async {
    final response = await _dio.get(
      '$baseUrl/api/admin/tracked-matches',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> addTrackedMatch(String token, String url, {String? homeLogoUrl, String? awayLogoUrl}) async {
    final response = await _dio.post(
      '$baseUrl/api/admin/tracked-matches',
      data: {
        'url': url,
        if (homeLogoUrl != null && homeLogoUrl.isNotEmpty) 'homeLogoUrl': homeLogoUrl,
        if (awayLogoUrl != null && awayLogoUrl.isNotEmpty) 'awayLogoUrl': awayLogoUrl,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['data'];
  }

  Future<void> removeTrackedMatch(String token, String id) async {
    await _dio.delete(
      '$baseUrl/api/admin/tracked-matches/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

