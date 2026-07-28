import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/turtle_model.dart';
import '../data/repositories/turtle_repository.dart';

/// 龟列表状态
class TurtleListState {
  final List<TurtleModel> turtles;
  final bool isLoading;
  final String? errorMessage;

  const TurtleListState({
    this.turtles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TurtleListState copyWith({
    List<TurtleModel>? turtles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TurtleListState(
      turtles: turtles ?? this.turtles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TurtleListNotifier extends StateNotifier<TurtleListState> {
  final TurtleRepository _repository;

  TurtleListNotifier(this._repository) : super(const TurtleListState());

  /// 加载所有龟
  Future<void> loadTurtles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final turtles = await _repository.getAll();
      state = state.copyWith(turtles: turtles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载失败，请稍后重试',
      );
    }
  }

  /// 创建龟
  Future<bool> createTurtle(Map<String, dynamic> data) async {
    try {
      final turtle = await _repository.create(data);
      state = state.copyWith(turtles: [...state.turtles, turtle]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: '创建失败，请稍后重试');
      return false;
    }
  }

  /// 更新龟
  Future<bool> updateTurtle(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _repository.update(id, data);
      state = state.copyWith(
        turtles: state.turtles.map((t) => t.id == id ? updated : t).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: '更新失败，请稍后重试');
      return false;
    }
  }

  /// 删除龟
  Future<bool> deleteTurtle(int id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        turtles: state.turtles.where((t) => t.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: '删除失败，请稍后重试');
      return false;
    }
  }
}

final turtleListProvider =
    StateNotifierProvider<TurtleListNotifier, TurtleListState>((ref) {
  return TurtleListNotifier(ref.watch(turtleRepositoryProvider));
});

/// 单个龟详情
final turtleDetailProvider =
    FutureProvider.family<TurtleModel, int>((ref, id) async {
  final repo = ref.watch(turtleRepositoryProvider);
  return repo.getById(id);
});
