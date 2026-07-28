import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/task_model.dart';

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  /// 获取所有任务
  Future<List<TaskModel>> getTasks({int? turtleId}) async {
    final response = await _dio.get('/api/tasks', queryParameters: {
      if (turtleId != null) 'turtleId': turtleId,
    });
    final list = response.data['data'] as List;
    return list.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取今日任务
  Future<List<TaskModel>> getTodayTasks({int? turtleId}) async {
    final response = await _dio.get('/api/tasks', queryParameters: {
      if (turtleId != null) 'turtleId': turtleId,
      'filter': 'today',
    });
    final list = response.data['data'] as List;
    return list.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 完成/取消完成任务
  Future<TaskModel> completeTask(int id, {bool completed = true}) async {
    final response = await _dio.put('/api/tasks/$id', data: {
      'isCompleted': completed,
    });
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});
