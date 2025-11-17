import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyJobEditPage extends StatefulWidget {
  const CompanyJobEditPage({super.key});

  @override
  State<CompanyJobEditPage> createState() => _CompanyJobEditPageState();
}

class _CompanyJobEditPageState extends State<CompanyJobEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  String _status = 'open';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: 求人データを取得してコントローラーにセット
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: 求人更新処理を実装
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('求人を更新しました')),
        );
        context.go('/company-portal/jobs/list');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('この求人を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // TODO: 求人削除処理を実装
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('求人を削除しました')),
          );
          context.go('/company-portal/jobs/list');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除エラー: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('求人編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイトル
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 給与
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: '給与',
                  border: OutlineInputBorder(),
                  hintText: '例: 月給30万円〜',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '給与を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 場所
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '場所',
                  border: OutlineInputBorder(),
                  hintText: '例: 東京都渋谷区',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '場所を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ステータス
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'ステータス',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('募集中')),
                  DropdownMenuItem(value: 'closed', child: Text('募集終了')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 更新ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _updateJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF323232),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFFFFF),
                        ),
                      )
                    : const Text('更新'),
              ),
              const SizedBox(height: 16),

              // 削除ボタン
              OutlinedButton(
                onPressed: _isLoading ? null : _deleteJob,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('削除'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
