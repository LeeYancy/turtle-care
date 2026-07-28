import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/turtle_model.dart';

class TurtleRepository {
  final Dio _dio;

  TurtleRepository(this._dio);

  /// 获取所有龟
  Future<List<TurtleModel>> getAll() async {
    final response = await _dio.get('/api/turtles');
    final list = response.data['data'] as List;
    return list.map((e) => TurtleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取单个龟详情
  Future<TurtleModel> getById(int id) async {
    final response = await _dio.get('/api/turtles/$id');
    return TurtleModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 创建龟
  Future<TurtleModel> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/turtles', data: data);
    return TurtleModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 更新龟
  Future<TurtleModel> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/turtles/$id', data: data);
    return TurtleModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 删除龟
  Future<void> delete(int id) async {
    await _dio.delete('/api/turtles/$id');
  }
}

final turtleRepositoryProvider = Provider<TurtleRepository>((ref) {
  return TurtleRepository(ref.watch(dioProvider));
});
