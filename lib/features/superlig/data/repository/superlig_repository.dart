import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/superlig_models.dart';
import '../../../../core/api_constants.dart';
import '../../../../core/token_storage.dart';

class SuperligRepository {
  final Dio _dio;
  final String baseUrl = ApiConstants.superligUrl;

  SuperligRepository({Dio? dio}) : _dio = dio ?? DioClient.getDio() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<List<StandingsEntry>> getStandings() async {
    try {
      final response = await _dio.get('$baseUrl/standings');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => StandingsEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Puan durumu alınamadı: $e');
    }
  }

  Future<List<Fixture>> getFixtures({int? week}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/fixtures',
        queryParameters: week != null ? {'week': week} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => Fixture.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Fikstür alınamadı: $e');
    }
  }

  Future<List<TopScorer>> getTopScorers() async {
    try {
      final response = await _dio.get('$baseUrl/top-scorers');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => TopScorer.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gol krallığı alınamadı: $e');
    }
  }

  Future<List<Transfer>> getTransfers({String? clubId}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/transfers',
        queryParameters: clubId != null ? {'clubId': clubId} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => Transfer.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Transferler alınamadı: $e');
    }
  }

  Future<List<LiveMatch>> getLiveMatches() async {
    try {
      final response = await _dio.get('$baseUrl/live-matches');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => LiveMatch.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Canlı maçlar yüklenirken hata oluştu: $e');
    }
  }

  Future<List<MatchComment>> getMatchComments(String matchId) async {
    try {
      final response = await _dio.get('$baseUrl/live-matches/$matchId/comments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MatchComment.fromJson(json)).toList();
      } else {
        throw Exception('Yorumlar alınamadı (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Yorumlar yüklenirken hata oluştu: $e');
    }
  }

  Future<MatchComment> addMatchComment(String matchId, String content) async {
    try {
      final token = await TokenStorage().getToken();
      final response = await _dio.post(
        '$baseUrl/live-matches/$matchId/comments', 
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201) {
        return MatchComment.fromJson(response.data['data']);
      } else {
        throw Exception('Yorum eklenemedi (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Yorum eklenirken hata: $e');
    }
  }

  Future<MatchDetailsData> getMatchDetails(String matchId) async {
    try {
      final response = await _dio.get('$baseUrl/live-matches/$matchId/details');
      if (response.statusCode == 200) {
        return MatchDetailsData.fromJson(response.data['data']);
      } else {
        throw Exception('Maç detayları alınamadı (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Maç detayları yüklenirken hata oluştu: $e');
    }
  }
}
