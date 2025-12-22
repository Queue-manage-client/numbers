// company_portal/presentation/pages/company_job_post_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyJobPostPage extends HookConsumerWidget {
  const CompanyJobPostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final salaryController = useTextEditingController();
    final locationController = useTextEditingController();
    final status = useState('open');
    final isLoading = useState(false);

    final postJob = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      final companyId = ref.read(currentCompanyIdProvider);
      if (companyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '企業IDが取得できません',
              style: TextStylePalette.normalText.copyWith(
                color: ColorPalette.neutral0,
              ),
            ),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
        return;
      }

      isLoading.value = true;

      try {
        final jobData = {
          'company_id': companyId,
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'salary': salaryController.text.trim(),
          'location': locationController.text.trim(),
          'status': status.value,
        };

        await ref.read(companyPortalRepositoryProvider).createJob(jobData);

        // 求人一覧を再取得
        ref.invalidate(companyJobsProvider);
        ref.invalidate(dashboardStatsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '求人を投稿しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGreen,
            ),
          );
          context.go('/company-portal/jobs');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '投稿エラー: $e',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }, [titleController, descriptionController, salaryController, locationController, status.value]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        title: const Text('求人投稿'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイトル
              Text(
                'タイトル',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: titleController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: Webエンジニア募集',
                  hintStyle: TextStylePalette.hintText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 説明
              Text(
                '説明',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: descriptionController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '求人の詳細を入力',
                  hintStyle: TextStylePalette.hintText,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 給与
              Text(
                '給与',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: salaryController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: 月給30万円〜',
                  hintStyle: TextStylePalette.hintText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '給与を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 場所
              Text(
                '勤務地',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: locationController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: 東京都渋谷区',
                  hintStyle: TextStylePalette.hintText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '勤務地を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // ステータス
              Text(
                'ステータス',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              DropdownButtonFormField<String>(
                value: status.value,
                style: TextStylePalette.normalText,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'open',
                    child: Text('募集中', style: TextStylePalette.normalText),
                  ),
                  DropdownMenuItem(
                    value: 'closed',
                    child: Text('募集終了', style: TextStylePalette.normalText),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    status.value = value;
                  }
                },
              ),
              const SizedBox(height: SpacePalette.lg * 2),

              // 投稿ボタン
              ElevatedButton(
                onPressed: isLoading.value ? null : postJob,
                child: isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorPalette.neutral0,
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