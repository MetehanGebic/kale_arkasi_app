import 'package:dio/dio.dart';
import '../../../core/api_constants.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final int teaBalance;
  final String? clubName;
  final String? clubSlug;
  final String? clubLogoUrl;
  final String? clubPrimaryColorHex;
  final String? clubSecondaryColorHex;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.teaBalance,
    this.clubName,
    this.clubSlug,
    this.clubLogoUrl,
    this.clubPrimaryColorHex,
    this.clubSecondaryColorHex,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      rank: json['rank'] as int,
      username: json['username'] as String,
      teaBalance: json['teaBalance'] as int,
      clubName: club?['name'] as String?,
      clubSlug: club?['slug'] as String?,
      clubLogoUrl: club?['logoUrl'] as String?,
      clubPrimaryColorHex: club?['primaryColor'] as String?,
      clubSecondaryColorHex: club?['secondaryColor'] as String?,
    );
  }
}

class LeaderboardRepository {
  final Dio _dio;
  final String _baseUrl = ApiConstants.economyUrl;

  LeaderboardRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // En çok çay biriktiren kullanıcıları sıralı şekilde getirir.
  Future<List<LeaderboardEntry>> getLeaderboard(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/leaderboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data'];
        return list
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(data['message'] ?? 'Liderlik tablosu alınamadı.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Liderlik tablosu alınamadı.',
      );
    }
  }
}
