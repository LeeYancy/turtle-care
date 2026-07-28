import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/chat_message_model.dart';
import '../models/health_record_model.dart';

class AIRepository {
  final Dio _dio;

  AIRepository(this._dio);

  /// AI 健康分析
  Future<HealthRecordModel> analyzeHealth({
    required int turtleId,
    required String symptoms,
    String? environmentInfo,
  }) async {
    final response = await _dio.post('/api/ai/analyze', data: {
      'turtleId': turtleId,
      'symptoms': symptoms,
      if (environmentInfo != null) 'environmentInfo': environmentInfo,
    });
    return HealthRecordModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 发送聊天消息
  Future<ChatMessageModel> sendChatMessage({
    int? turtleId,
    required String content,
  }) async {
    final response = await _dio.post('/api/ai/chat', data: {
      if (turtleId != null) 'turtleId': turtleId,
      'content': content,
    });
    return ChatMessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取聊天历史
  Future<List<ChatMessageModel>> getChatHistory({int? turtleId}) async {
    final response = await _dio.get('/api/ai/history', queryParameters: {
      if (turtleId != null) 'turtleId': turtleId,
    });
    final list = response.data['data'] as List;
    return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取健康记录列表
  Future<List<HealthRecordModel>> getHealthRecords(int turtleId) async {
    final response = await _dio.get('/api/ai/history', queryParameters: {
      'turtleId': turtleId,
      'type': 'health',
    });
    final list = response.data['data'] as List;
    return list.map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository(ref.watch(dioProvider));
});
