import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/task_provider.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskListProvider);
    final filteredTasks = state.filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日常任务'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(
            currentFilter: state.filter,
            onFilterChanged: (f) =>
                ref.read(taskListProvider.notifier).setFilter(f),
            todayCount: state.todayCount,
            completedCount: state.tasks.where((t) => t.isCompleted).length,
            totalCount: state.tasks.length,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(taskListProvider.notifier).loadTasks(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredTasks.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.task_alt,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无任务',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _TaskCard(
                        title: task.title,
                        description: task.description,
                        scheduledTime: task.scheduledTime,
                        isCompleted: task.isCompleted,
                        onToggle: () => ref
                            .read(taskListProvider.notifier)
                            .toggleTask(task),
                      );
                    },
                  ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final int todayCount;
  final int completedCount;
  final int totalCount;

  const _FilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.todayCount,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _FilterChip(
            label: '全部',
            count: totalCount,
            selected: currentFilter == TaskFilter.all,
            onTap: () => onFilterChanged(TaskFilter.all),
          ),
          _FilterChip(
            label: '今日',
            count: todayCount,
            selected: currentFilter == TaskFilter.today,
            onTap: () => onFilterChanged(TaskFilter.today),
          ),
          _FilterChip(
            label: '已完成',
            count: completedCount,
            selected: currentFilter == TaskFilter.completed,
            onTap: () => onFilterChanged(TaskFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime scheduledTime;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.isCompleted,
    required this.onToggle,
  });

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(scheduledTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isToday)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '今日',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  _formatDate(scheduledTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
