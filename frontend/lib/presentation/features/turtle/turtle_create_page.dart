import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/turtle_provider.dart';

class TurtleCreatePage extends ConsumerStatefulWidget {
  const TurtleCreatePage({super.key});

  @override
  ConsumerState<TurtleCreatePage> createState() => _TurtleCreatePageState();
}

class _TurtleCreatePageState extends ConsumerState<TurtleCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _shellLengthController = TextEditingController();
  final _notesController = TextEditingController();

  String _species = '';
  DateTime? _birthDate;
  DateTime? _adoptDate;
  bool _isSubmitting = false;

  static const _speciesOptions = [
    '巴西龟（红耳龟）',
    '草龟（中华草龟）',
    '黄缘闭壳龟',
    '花龟（中华花龟）',
    '地图龟',
    '剃刀龟',
    '麝香龟',
    '鳄龟',
    '苏卡达陆龟',
    '赫曼陆龟',
    '其他',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _shellLengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isBirth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _adoptDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_species.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择品种')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'species': _species,
      if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String(),
      if (_adoptDate != null) 'adoptDate': _adoptDate!.toIso8601String(),
      if (_weightController.text.isNotEmpty)
        'weight': double.tryParse(_weightController.text),
      if (_shellLengthController.text.isNotEmpty)
        'shellLength': double.tryParse(_shellLengthController.text),
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    final success =
        await ref.read(turtleListProvider.notifier).createTurtle(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('添加成功')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(turtleListProvider).errorMessage ?? '创建失败'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加我的龟')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像占位
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('图片选择功能开发中')),
                  );
                },
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.camera_alt,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              // 名字
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '龟的名字',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入龟的名字';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 品种
              DropdownButtonFormField<String>(
                value: _species.isEmpty ? null : _species,
                decoration: const InputDecoration(
                  labelText: '品种',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _speciesOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _species = v ?? ''),
              ),
              const SizedBox(height: 16),

              // 体重
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '体重 (克)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return '请输入有效数字';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 背甲长
              TextFormField(
                controller: _shellLengthController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '背甲长 (厘米)',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return '请输入有效数字';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 出生日期
              InkWell(
                onTap: () => _pickDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '出生日期',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_birthDate != null
                      ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
                      : '选择日期'),
                ),
              ),
              const SizedBox(height: 16),

              // 领养日期
              InkWell(
                onTap: () => _pickDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '领养日期',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_adoptDate != null
                      ? '${_adoptDate!.year}-${_adoptDate!.month.toString().padLeft(2, '0')}-${_adoptDate!.day.toString().padLeft(2, '0')}'
                      : '选择日期'),
                ),
              ),
              const SizedBox(height: 16),

              // 备注
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '备注',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  hintText: '其他信息，如来源、特征等',
                ),
              ),
              const SizedBox(height: 24),

              // 提交
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
