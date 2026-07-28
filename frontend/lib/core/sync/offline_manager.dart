import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/turtle_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/health_record_model.dart';

/// 离线缓存管理器
/// 使用 Hive 实现本地数据缓存，支持离线查看和后续同步
class OfflineManager {
  static const _turtleBox = 'turtles_cache';
  static const _taskBox = 'tasks_cache';
  static const _chatBox = 'chat_cache';
  static const _healthBox = 'health_cache';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_turtleBox);
    await Hive.openBox(_taskBox);
    await Hive.openBox(_chatBox);
    await Hive.openBox(_healthBox);
    _initialized = true;
  }

  // === 龟数据缓存 ===

  Future<void> cacheTurtles(List<TurtleModel> turtles) async {
    final box = Hive.box(_turtleBox);
    await box.clear();
    for (final t in turtles) {
      await box.put('turtle_${t.id}', t.toJson());
    }
    await box.put('cache_time', DateTime.now().toIso8601String());
  }

  List<TurtleModel> getCachedTurtles() {
    final box = Hive.box(_turtleBox);
    final results = <TurtleModel>[];
    for (final key in box.keys) {
      if (key == 'cache_time') continue;
      final data = box.get(key);
      if (data is Map) {
        results.add(TurtleModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return results;
  }

  DateTime? getTurtlesCacheTime() {
    final box = Hive.box(_turtleBox);
    final time = box.get('cache_time');
    return time != null ? DateTime.parse(time as String) : null;
  }

  // === 任务数据缓存 ===

  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final box = Hive.box(_taskBox);
    await box.clear();
    for (final t in tasks) {
      await box.put('task_${t.id}', t.toJson());
    }
    await box.put('cache_time', DateTime.now().toIso8601String());
  }

  List<TaskModel> getCachedTasks() {
    final box = Hive.box(_taskBox);
    final results = <TaskModel>[];
    for (final key in box.keys) {
      if (key == 'cache_time') continue;
      final data = box.get(key);
      if (data is Map) {
        results.add(TaskModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return results;
  }

  // === 聊天记录缓存 ===

  Future<void> cacheChatMessages(List<ChatMessageModel> messages) async {
    final box = Hive.box(_chatBox);
    await box.clear();
    for (final m in messages) {
      await box.put('msg_${m.id}', m.toJson());
    }
    await box.put('cache_time', DateTime.now().toIso8601String());
  }

  List<ChatMessageModel> getCachedChatMessages() {
    final box = Hive.box(_chatBox);
    final results = <ChatMessageModel>[];
    final keys = box.keys.where((k) => k != 'cache_time').toList();
    for (final key in keys) {
      final data = box.get(key);
      if (data is Map) {
        results.add(ChatMessageModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results;
  }

  // === 健康记录缓存 ===

  Future<void> cacheHealthRecords(
      int turtleId, List<HealthRecordModel> records) async {
    final box = Hive.box(_healthBox);
    await box.put('health_$turtleId', records.map((r) => r.toJson()).toList());
    await box.put('health_${turtleId}_time', DateTime.now().toIso8601String());
  }

  List<HealthRecordModel> getCachedHealthRecords(int turtleId) {
    final box = Hive.box(_healthBox);
    final data = box.get('health_$turtleId');
    if (data is! List) return [];
    return data
        .map((e) =>
            HealthRecordModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // === 清理 ===

  Future<void> clearAll() async {
    await Hive.box(_turtleBox).clear();
    await Hive.box(_taskBox).clear();
    await Hive.box(_chatBox).clear();
    await Hive.box(_healthBox).clear();
  }

  /// 判断缓存是否过期（超过30分钟）
  bool isCacheStale(DateTime? cacheTime) {
    if (cacheTime == null) return true;
    return DateTime.now().difference(cacheTime).inMinutes > 30;
  }
}

final offlineManagerProvider = Provider<OfflineManager>((ref) {
  return OfflineManager();
});
