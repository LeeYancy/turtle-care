import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';

enum TaskFilter { all, today, completed }

/// 任务列表状态
class TaskListState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  final TaskFilter filter;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = TaskFilter.all,
  });

  List<TaskModel> get filteredTasks {
    switch (filter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.today:
        final now = DateTime.now();
        return tasks
            .where((t) =>
                t.scheduledTime.year == now.year &&
                t.scheduledTime.month == now.month &&
                t.scheduledTime.day == now.day)
            .toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.isCompleted).toList();
    }
  }

  int get todayCount {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.scheduledTime.year == now.year &&
            t.scheduledTime.month == now.month &&
            t.scheduledTime.day == now.day)
        .length;
  }

  int get todayCompletedCount {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.scheduledTime.year == now.year &&
            t.scheduledTime.month == now.month &&
            t.scheduledTime.day == now.day &&
            t.isCompleted)
        .length;
  }

  TaskListState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    TaskFilter? filter,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;

  TaskListNotifier(this._repository) : super(const TaskListState());

  /// 加载任务
  Future<void> loadTasks({int? turtleId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tasks = await _repository.getTasks(turtleId: turtleId);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载任务失败',
      );
    }
  }

  /// 加载今日任务
  Future<void> loadTodayTasks({int? turtleId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tasks = await _repository.getTodayTasks(turtleId: turtleId);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载今日任务失败',
      );
    }
  }

  /// 切换过滤条件
  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// 完成/取消完成任务
  Future<void> toggleTask(TaskModel task) async {
    try {
      final updated = await _repository.completeTask(
        task.id,
        completed: !task.isCompleted,
      );
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == task.id ? updated : t).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '操作失败');
    }
  }
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(ref.watch(taskRepositoryProvider));
});
