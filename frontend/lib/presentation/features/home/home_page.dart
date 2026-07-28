import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_provider.dart';
import '../../../services/turtle_provider.dart';
import '../../../services/task_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
      ref.read(turtleListProvider.notifier).loadTurtles();
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final turtleState = ref.watch(turtleListProvider);
    final taskState = ref.watch(taskListProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('懂养龟'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout().then((_) {
                  context.go('/login');
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20),
                    const SizedBox(width: 8),
                    Text(authState.isAuthenticated ? '退出登录' : '登录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(turtleListProvider.notifier).loadTurtles(),
            ref.read(taskListProvider.notifier).loadTasks(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎语
              if (authState.user != null)
                Text(
                  '你好，${authState.user!.nickname}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              const SizedBox(height: 16),

              // 龟列表卡片
              _TurtleSection(state: turtleState),
              const SizedBox(height: 16),

              // 今日任务
              _TodayTasksCard(taskState: taskState),
              const SizedBox(height: 16),

              // 快捷入口
              _QuickActions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai/chat'),
        icon: const Icon(Icons.chat_bubble),
        label: const Text('AI咨询'),
      ),
    );
  }
}

class _TurtleSection extends StatelessWidget {
  final TurtleListState state;

  const _TurtleSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Card(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.turtles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.pets,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('还没有添加龟龟'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/turtle/create'),
                icon: const Icon(Icons.add),
                label: const Text('添加我的龟'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.turtles.length + 1,
        itemBuilder: (context, index) {
          if (index == state.turtles.length) {
            return _AddTurtleCard();
          }
          final turtle = state.turtles[index];
          return _TurtleCard(
            name: turtle.name,
            species: turtle.species,
            photoUrl: turtle.photoUrl,
            onTap: () => context.push('/turtle/${turtle.id}'),
          );
        },
      ),
    );
  }
}

class _TurtleCard extends StatelessWidget {
  final String name;
  final String species;
  final String? photoUrl;
  final VoidCallback onTap;

  const _TurtleCard({
    required this.name,
    required this.species,
    this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.pets, size: 32)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(species,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTurtleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => context.push('/turtle/create'),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text('添加龟龟',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  final TaskListState taskState;

  const _TodayTasksCard({required this.taskState});

  @override
  Widget build(BuildContext context) {
    final total = taskState.todayCount;
    final completed = taskState.todayCompletedCount;

    return Card(
      child: InkWell(
        onTap: () => context.push('/tasks'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('今日任务',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('$completed / $total',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              if (total == 0)
                const Text('暂无任务', style: TextStyle(color: Colors.grey))
              else
                LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.health_and_safety,
            label: '健康分析',
            onTap: () => context.push('/ai/health'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.task_alt,
            label: '日常任务',
            onTap: () => context.push('/tasks'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.chat_bubble,
            label: 'AI咨询',
            onTap: () => context.push('/ai/chat'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
