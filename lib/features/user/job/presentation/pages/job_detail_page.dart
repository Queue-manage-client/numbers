// job/presentation/pages/job_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final jobAsync = ref.watch(jobProvider(jobId));
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '求人詳細',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return Center(
              child: Text(
                '求人が見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          final company = job['companies'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? '求人名未設定',
                        style: TextStylePalette.lgListTitle,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        company?['name'] ?? '企業名未設定',
                        style: TextStylePalette.lgListLeading,
                      ),
                      const SizedBox(height: SpacePalette.lg),
                      _buildSection('給与', job['salary'] ?? '未設定'),
                      _buildSection('仕事内容', job['description'] ?? '未設定'),
                      _buildSection('勤務地', job['location']?.toString() ?? '未設定'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'エラー: $error',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            decoration: BoxDecoration(
              color: ColorPalette.neutral900,
              border: Border(
                top: BorderSide(
                  color: ColorPalette.neutral600,
                  width: 1,
                ),
              ),
            ),
            child: GradientButton(
              text: '応募する',
              onPressed: () {
                context.push('/jobs/$jobId/apply/confirm');
              },
              icon: const Icon(
                Icons.north_east,
                color: ColorPalette.neutral0,
                size: 20,
              ),
            ),
          ),
          AppFooter(currentRoute: currentRoute),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStylePalette.smHeader,
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            content,
            style: TextStylePalette.subText,
          ),
        ],
      ),
    );
  }
}
