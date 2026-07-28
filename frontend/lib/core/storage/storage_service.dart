import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final p = await prefs;
    await p.setString(_tokenKey, token);
  }

  Future<void> clearAuth() async {
    final p = await prefs;
    await p.remove(_tokenKey);
    await p.remove(_userIdKey);
  }
}
