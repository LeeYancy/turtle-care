import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/features/auth/auth_page.dart';
import '../presentation/features/home/home_page.dart';
import '../presentation/features/turtle/turtle_create_page.dart';
import '../presentation/features/turtle/turtle_detail_page.dart';
import '../presentation/features/ai_chat/ai_chat_page.dart';
import '../presentation/features/ai_chat/health_analysis_page.dart';
import '../presentation/features/tasks/tasks_page.dart';
import '../services/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/turtle/create',
        name: 'turtle-create',
        builder: (context, state) => const TurtleCreatePage(),
      ),
      GoRoute(
        path: '/turtle/:id',
        name: 'turtle-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TurtleDetailPage(turtleId: int.parse(id));
        },
      ),
      GoRoute(
        path: '/ai/chat',
        name: 'ai-chat',
        builder: (context, state) => const AIChatPage(),
      ),
      GoRoute(
        path: '/ai/health',
        name: 'health-analysis',
        builder: (context, state) => const HealthAnalysisPage(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksPage(),
      ),
    ],
  );
});
