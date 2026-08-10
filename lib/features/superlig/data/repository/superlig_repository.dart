import 'package:dio/dio.dart';
import '../models/superlig_models.dart';
import '../../../../core/api_constants.dart';

class SuperligRepository {
  final Dio _dio;
  final String baseUrl = ApiConstants.superligUrl;

  SuperligRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
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
}
