import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyJobPostPage extends ConsumerStatefulWidget {
  const CompanyJobPostPage({super.key});

  @override
  ConsumerState<CompanyJobPostPage> createState() => _CompanyJobPostPageState();
}

class _CompanyJobPostPageState extends ConsumerState<CompanyJobPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  String _status = 'open';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('企業IDが取得できません')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jobData = {
        'company_id': companyId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'salary': _salaryController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _status,
      };

      await ref.read(companyPortalRepositoryProvider).createJob(jobData);

      // 求人一覧を再取得
      ref.invalidate(companyJobsProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('求人を投稿しました')),
        );
        context.go('/company-portal/jobs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: const Text('求人投稿'),
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

              // 投稿ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _postJob,
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
                    : const Text('投稿'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
