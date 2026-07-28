import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/turtle_provider.dart';

class TurtleDetailPage extends ConsumerStatefulWidget {
  final int turtleId;

  const TurtleDetailPage({super.key, required this.turtleId});

  @override
  ConsumerState<TurtleDetailPage> createState() => _TurtleDetailPageState();
}

class _TurtleDetailPageState extends ConsumerState<TurtleDetailPage> {
  List<HealthRecordModel> _healthRecords = [];
  List<TaskModel> _tasks = [];
  bool _isLoadingHealth = true;
  bool _isLoadingTasks = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final aiRepo = ref.read(aiRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    try {
      final records = await aiRepo.getHealthRecords(widget.turtleId);
      if (mounted) {
        setState(() {
          _healthRecords = records;
          _isLoadingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHealth = false);
    }

    try {
      final tasks = await taskRepo.getTasks(turtleId: widget.turtleId);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final turtleAsync = ref.watch(turtleDetailProvider(widget.turtleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('龟档案'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: 编辑功能
            },
          ),
        ],
      ),
      body: turtleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .invalidate(turtleDetailProvider(widget.turtleId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (turtle) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(turtleDetailProvider(widget.turtleId));
            await _loadData();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 头像区域
              Card(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: turtle.photoUrl != null
                        ? Image.network(
                            turtle.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(context),
                          )
                        : _photoPlaceholder(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 基本信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(turtle.name,
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 8),
                          if (!turtle.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('已归档',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const Divider(),
                      _InfoRow(label: '品种', value: turtle.species),
                      _InfoRow(
                        label: '出生日期',
                        value: turtle.birthDate != null
                            ? '${turtle.birthDate!.year}-${turtle.birthDate!.month.toString().padLeft(2, '0')}-${turtle.birthDate!.day.toString().padLeft(2, '0')}'
                            : '--',
                      ),
                      _InfoRow(
                        label: '领养日期',
                        value: turtle.adoptDate != null
                            ? '${turtle.adoptDate!.year}-${turtle.adoptDate!.month.toString().padLeft(2, '0')}-${turtle.adoptDate!.day.toString().padLeft(2, '0')}'
                            : '--',
                      ),
                      _InfoRow(
                        label: '体重',
                        value: turtle.weight != null
                            ? '${turtle.weight} g'
                            : '--',
                      ),
                      _InfoRow(
                        label: '背甲长',
                        value: turtle.shellLength != null
                            ? '${turtle.shellLength} cm'
                            : '--',
                      ),
                      if (turtle.notes != null && turtle.notes!.isNotEmpty)
                        _InfoRow(label: '备注', value: turtle.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 健康记录
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('健康记录',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/ai/health'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('分析'),
                          ),
                        ],
                      ),
                      if (_isLoadingHealth)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_healthRecords.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('暂无记录',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._healthRecords.take(3).map((r) =>
                            _HealthRecordTile(record: r)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 任务列表
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('任务',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => context.push('/tasks'),
                            child: const Text('查看全部'),
                          ),
                        ],
                      ),
                      if (_isLoadingTasks)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_tasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('暂无任务',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._tasks.take(5).map((t) => _TaskTile(
                              task: t,
                              onToggle: () async {
                                final repo =
                                    ref.read(taskRepositoryProvider);
                                final updated = await repo.completeTask(
                                  t.id,
                                  completed: !t.isCompleted,
                                );
                                setState(() {
                                  _tasks = _tasks
                                      .map((item) =>
                                          item.id == t.id ? updated : item)
                                      .toList();
                                });
                              },
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pets,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        const Text('暂无照片', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _HealthRecordTile extends StatelessWidget {
  final HealthRecordModel record;

  const _HealthRecordTile({required this.record});

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'high':
        return '高风险';
      case 'medium':
        return '中风险';
      default:
        return '低风险';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(record.symptoms, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        record.aiDiagnosis,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _riskColor(record.riskLevel).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _riskLabel(record.riskLevel),
          style: TextStyle(
            color: _riskColor(record.riskLevel),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;

  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: Text(task.description,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
    );
  }
}
