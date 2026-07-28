import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class TurtleCareApp extends ConsumerWidget {
  const TurtleCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '懂养龟',
      debugShowCheckedModeBanner: false,
      theme: TurtleCareTheme.light,
      routerConfig: router,
    );
  }
}
