// company/presentation/pages/company_job_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyJobListPage extends ConsumerWidget {
  const CompanyJobListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final jobsAsync = ref.watch(companyJobsProvider(companyId));
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '求人一覧',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                '求人がありません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final jobId = job['id'] as String? ?? '';
              final title = job['title'] as String? ?? 'タイトルなし';
              final salary = job['salary'] as String? ?? '給与未設定';
              final location = job['location'] as String? ?? '勤務地未設定';
              final description = job['description'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: SpacePalette.base),
                color: ColorPalette.neutral800,
                child: InkWell(
                  onTap: () {
                    context.push('/jobs/$jobId');
                  },
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStylePalette.smListTitle,
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: ColorPalette.neutral400,
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            Text(
                              salary,
                              style: TextStylePalette.subText,
                            ),
                            const SizedBox(width: SpacePalette.base),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: ColorPalette.neutral400,
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStylePalette.subText,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: SpacePalette.sm),
                          Text(
                            description,
                            style: TextStylePalette.smListLeading,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: SpacePalette.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.chevron_right,
                            color: ColorPalette.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'エラー: $error',
                style: TextStylePalette.subText,
              ),
              const SizedBox(height: SpacePalette.base),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(companyJobsProvider(companyId));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primaryColor,
                  side: const BorderSide(
                    color: ColorPalette.primaryColor,
                    width: 2,
                  ),
                ),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
