import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company/presentation/providers/company_provider.dart';

class CompanyInternListPage extends ConsumerWidget {
  const CompanyInternListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final internshipsAsync = ref.watch(companyInternshipsProvider(companyId));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('インターン一覧'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: internshipsAsync.when(
        data: (internships) {
          if (internships.isEmpty) {
            return const Center(
              child: Text('インターンがありません'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    context.push('/interns/$internshipId');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323232),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF666666),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateRange,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF666666),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(companyInternshipsProvider(companyId));
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
