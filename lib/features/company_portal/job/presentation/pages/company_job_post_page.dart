// company_portal/job/presentation/pages/company_job_post_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/job/presentation/providers/company_job_provider.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/features/company_portal/subscription/presentation/providers/subscription_providers.dart';
import 'package:numbers/features/company_portal/subscription/presentation/widgets/subscription_required_overlay.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class CompanyJobPostPage extends ConsumerWidget {
  const CompanyJobPostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPost = ref.watch(canPostProvider);
    if (!canPost) return const SubscriptionRequiredOverlay();
    return const _CompanyJobPostPageBody();
  }
}

class _CompanyJobPostPageBody extends HookConsumerWidget {
  const _CompanyJobPostPageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final salaryController = useTextEditingController();
    final locationController = useTextEditingController();
    final workingHoursController = useTextEditingController();
    final salaryMinController = useTextEditingController();
    final salaryMaxController = useTextEditingController();
    final status = useState('open');
    final jobType = useState<String?>(null);
    final jobCategory = useState<String?>(null);
    final isLoading = useState(false);

    final postJob = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        // Get coordinates from address using Geocoding
        double? latitude;
        double? longitude;
        final address = locationController.text.trim();

        if (address.isNotEmpty) {
          final geocodingService = ref.read(geocodingServiceProvider);
          final result =
              await geocodingService.getCoordinatesFromAddress(address);
          if (result != null) {
            latitude = result.latitude;
            longitude = result.longitude;
          }
        }

        final salaryMin = salaryMinController.text.trim().isNotEmpty
            ? int.tryParse(salaryMinController.text.trim())
            : null;
        final salaryMax = salaryMaxController.text.trim().isNotEmpty
            ? int.tryParse(salaryMaxController.text.trim())
            : null;

        final notifier = ref.read(companyJobNotifierProvider.notifier);
        final job = await notifier.create(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          salary: salaryController.text.trim().isNotEmpty
              ? salaryController.text.trim()
              : null,
          location: address.isNotEmpty ? address : null,
          jobType: jobType.value,
          jobCategory: jobCategory.value,
          workingHours: workingHoursController.text.trim().isNotEmpty
              ? workingHoursController.text.trim()
              : null,
          salaryMin: salaryMin,
          salaryMax: salaryMax,
          status: status.value,
          latitude: latitude,
          longitude: longitude,
        );

        if (context.mounted) {
          if (job != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '求人を投稿しました',
                  style: TextStylePalette.normalText
                      .copyWith(color: ColorPalette.neutral0),
                ),
                backgroundColor: ColorPalette.systemGold,
              ),
            );
            context.go('/company-portal/jobs');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '投稿に失敗しました',
                  style: TextStylePalette.normalText
                      .copyWith(color: ColorPalette.neutral0),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '投稿エラー: $e',
                style: TextStylePalette.normalText
                    .copyWith(color: ColorPalette.neutral0),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }, [
      titleController,
      descriptionController,
      salaryController,
      locationController,
      workingHoursController,
      salaryMinController,
      salaryMaxController,
      status.value,
      jobType.value,
      jobCategory.value,
    ]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () { if (Navigator.of(context).canPop()) { context.pop(); } else { context.go("/feed"); } },
        ),
        title: const Text('求人投稿'),
      ),
      bottomNavigationBar: const AppFooter(currentRoute: '/company-portal/jobs/post'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイトル
              Text('タイトル', style: TextStylePalette.smTitle),
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

              // 職種カテゴリ
              Text('職種カテゴリ', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              DropdownButtonFormField<String>(
                value: jobCategory.value,
                style: TextStylePalette.normalText,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '選択してください',
                ),
                items: JobCategory.all
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child:
                              Text(cat, style: TextStylePalette.normalText),
                        ))
                    .toList(),
                onChanged: (value) {
                  jobCategory.value = value;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 雇用形態
              Text('雇用形態', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              DropdownButtonFormField<String>(
                value: jobType.value,
                style: TextStylePalette.normalText,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '選択してください',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'full_time', child: Text('正社員')),
                  DropdownMenuItem(
                      value: 'part_time', child: Text('バイト')),
                  DropdownMenuItem(
                      value: 'new_grad', child: Text('新卒')),
                  DropdownMenuItem(
                      value: 'mid_career', child: Text('中途')),
                ],
                onChanged: (value) {
                  jobType.value = value;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 説明
              Text('仕事内容', style: TextStylePalette.smTitle),
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
                    return '仕事内容を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.base),

              // 月給範囲
              Text('月給（万円）', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: salaryMinController,
                      style: TextStylePalette.normalText,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '下限',
                        hintStyle: TextStylePalette.hintText,
                        suffixText: '万円',
                        suffixStyle: TextStylePalette.smText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.sm),
                    child: Text('〜',
                        style: TextStylePalette.normalText),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: salaryMaxController,
                      style: TextStylePalette.normalText,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '上限',
                        hintStyle: TextStylePalette.hintText,
                        suffixText: '万円',
                        suffixStyle: TextStylePalette.smText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacePalette.sm),

              // 給与（テキスト）
              TextFormField(
                controller: salaryController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '補足: 例: 賞与年2回、交通費支給',
                  hintStyle: TextStylePalette.hintText,
                ),
              ),
              const SizedBox(height: SpacePalette.base),

              // 勤務時間
              Text('勤務時間', style: TextStylePalette.smTitle),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: workingHoursController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: 9:00〜18:00（休憩1時間）',
                  hintStyle: TextStylePalette.hintText,
                ),
              ),
              const SizedBox(height: SpacePalette.base),

              // 勤務地
              Text('勤務地', style: TextStylePalette.smTitle),
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
              Text('ステータス', style: TextStylePalette.smTitle),
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
                    child:
                        Text('募集中', style: TextStylePalette.normalText),
                  ),
                  DropdownMenuItem(
                    value: 'closed',
                    child:
                        Text('募集終了', style: TextStylePalette.normalText),
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
