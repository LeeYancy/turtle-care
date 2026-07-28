import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/sync/offline_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 离线缓存
  final offlineManager = OfflineManager();
  await offlineManager.init();

  runApp(
    const ProviderScope(
      child: TurtleCareApp(),
    ),
  );
}
