import 'package:dio/dio.dart';
import '../../../core/api_constants.dart';

class TaskItem {
  final String id;
  final String title;
  final String? description;
  final int rewardTea;
  final String actionType;
  final bool completedToday;

  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.rewardTea,
    required this.actionType,
    required this.completedToday,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      rewardTea: json['rewardTea'] as int,
      actionType: json['actionType'] as String,
      completedToday: json['completedToday'] as bool? ?? false,
    );
  }
}

class TasksRepository {
  final Dio _dio;
  final String _baseUrl = ApiConstants.tasksUrl;

  TasksRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // Aktif görevleri, her biri için "bugün tamamlandı mı" bilgisiyle çeker.
  Future<List<TaskItem>> getTasks(String token) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data'];
        return list
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(data['message'] ?? 'Görevler alınamadı.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Görevler alınamadı.');
    }
  }

  // Bir görevi tamamlar ve { message, reward, newBalance } döner.
  Future<Map<String, dynamic>> completeTask(String token, String taskId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/$taskId/complete',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Görev tamamlanamadı.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Görev tamamlanamadı.');
    }
  }
}
