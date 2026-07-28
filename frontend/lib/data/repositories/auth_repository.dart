import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepository(this._dio, this._storage);

  /// 登录
  Future<({UserModel user, String token})> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/api/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.setToken(token);
    return (user: user, token: token);
  }

  /// 注册
  Future<({UserModel user, String token})> register({
    required String phone,
    required String password,
    required String nickname,
  }) async {
    final response = await _dio.post('/api/auth/register', data: {
      'phone': phone,
      'password': password,
      'nickname': nickname,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.setToken(token);
    return (user: user, token: token);
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } finally {
      await _storage.clearAuth();
    }
  }

  /// 获取本地 token
  Future<String?> getToken() => _storage.getToken();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(storageServiceProvider));
});
