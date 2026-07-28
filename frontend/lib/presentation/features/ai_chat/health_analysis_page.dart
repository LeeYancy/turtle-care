import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../services/turtle_provider.dart';

class HealthAnalysisPage extends ConsumerStatefulWidget {
  const HealthAnalysisPage({super.key});

  @override
  ConsumerState<HealthAnalysisPage> createState() =>
      _HealthAnalysisPageState();
}

class _HealthAnalysisPageState extends ConsumerState<HealthAnalysisPage> {
  final _symptomsController = TextEditingController();
  final _envController = TextEditingController();
  int? _selectedTurtleId;
  bool _isAnalyzing = false;
  HealthRecordModel? _result;

  @override
  void dispose() {
    _symptomsController.dispose();
    _envController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请描述龟的症状')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final repo = ref.read(aiRepositoryProvider);
      final record = await repo.analyzeHealth(
        turtleId: _selectedTurtleId ?? 0,
        symptoms: _symptomsController.text.trim(),
        environmentInfo: _envController.text.trim().isEmpty
            ? null
            : _envController.text.trim(),
      );
      setState(() {
        _result = record;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分析失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final turtleState = ref.watch(turtleListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI健康分析')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择龟
            if (turtleState.turtles.isNotEmpty) ...[
              Text('选择龟龟', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedTurtleId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                hint: const Text('选择要分析的龟'),
                items: turtleState.turtles
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.species})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTurtleId = v),
              ),
              const SizedBox(height: 16),
            ],

            // 症状描述
            Text('请描述龟的症状', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _symptomsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '例如：不吃东西3天，总是浮在水面上，眼睛肿胀...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 环境信息
            Text('环境信息（可选）', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _envController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '水温、水质、近期变化等...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 分析按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety),
                label: Text(_isAnalyzing ? '分析中...' : '开始分析'),
              ),
            ),

            // 分析结果
            if (_result != null) ...[
              const SizedBox(height: 24),
              _AnalysisResultCard(record: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  final HealthRecordModel record;

  const _AnalysisResultCard({required this.record});

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

  IconData _riskIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.dangerous;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(record.riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_riskIcon(record.riskLevel), color: color, size: 28),
                const SizedBox(width: 8),
                Text('分析结果',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _riskLabel(record.riskLevel),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // AI 诊断
            Text('AI诊断', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(record.aiDiagnosis,
                  style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 16),

            // 建议
            if (record.recommendations.isNotEmpty) ...[
              Text('养护建议', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Text(record.recommendations,
                    style: const TextStyle(height: 1.5)),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/ai/chat'),
                  icon: const Icon(Icons.chat_bubble, size: 18),
                  label: const Text('继续咨询'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
