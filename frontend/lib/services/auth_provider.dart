import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// 认证状态
class AuthState extends Equatable {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props =>
      [user, token, isLoading, errorMessage, isAuthenticated];
}

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// 初始化：检查本地 token
  Future<void> checkAuth() async {
    final token = await _repository.getToken();
    if (token != null) {
      state = state.copyWith(token: token, isAuthenticated: true);
    }
  }

  /// 登录
  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.login(phone: phone, password: password);
      state = AuthState(
        user: result.user,
        token: result.token,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e),
      );
      return false;
    }
  }

  /// 注册
  Future<bool> register(String phone, String password, String nickname) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.register(
        phone: phone,
        password: password,
        nickname: nickname,
      );
      state = AuthState(
        user: result.user,
        token: result.token,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e),
      );
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    final str = e.toString();
    if (str.contains('401')) return '手机号或密码错误';
    if (str.contains('400')) return '该手机号已注册';
    if (str.contains('SocketException') || str.contains('Connection refused')) {
      return '网络连接失败，请检查网络';
    }
    return '操作失败，请稍后重试';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
