// company/presentation/pages/company_intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';

import 'package:numbers/core/theme/app_theme.dart';

class CompanyInternListPage extends ConsumerWidget {
  const CompanyInternListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final internshipsAsync = ref.watch(companyInternshipsProvider(companyId));
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'インターン一覧',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      body: internshipsAsync.when(
        data: (internships) {
          if (internships.isEmpty) {
            return Center(
              child: Text(
                'インターンがありません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final internship = internships[index];
              final internshipId = internship['id'] as String? ?? '';
              final title = internship['title'] as String? ?? 'タイトルなし';
              final description = internship['description'] as String? ?? '';
              final startDate = internship['start_date'] as String?;
              final endDate = internship['end_date'] as String?;

              String dateRange = '期間未設定';
              if (startDate != null && endDate != null) {
                dateRange = '$startDate 〜 $endDate';
              } else if (startDate != null) {
                dateRange = '$startDate 〜';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: SpacePalette.base),
                color: ColorPalette.neutral800,
                child: InkWell(
                  onTap: () {
                    context.push('/interns/$internshipId');
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
                              Icons.calendar_today,
                              size: 16,
                              color: ColorPalette.neutral400,
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            Text(
                              dateRange,
                              style: TextStylePalette.subText,
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
                  ref.invalidate(companyInternshipsProvider(companyId));
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
