// company_portal/presentation/pages/company_job_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyJobManagementPage extends ConsumerWidget {
  const CompanyJobManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        title: const Text('求人管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/company-portal/jobs/post'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規求人投稿'),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/jobs/list'),
                    icon: Icon(
                      Icons.list,
                      color: ColorPalette.primaryColor,
                    ),
                    label: const Text('求人一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                      side: const BorderSide(
                        color: ColorPalette.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            Text(
              '投稿済み求人',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),
            Expanded(
              child: jobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 80,
                            color: ColorPalette.neutral400,
                          ),
                          const SizedBox(height: SpacePalette.lg),
                          Text(
                            '投稿済みの求人はありません',
                            style: TextStylePalette.header,
                          ),
                          const SizedBox(height: SpacePalette.sm),
                          Text(
                            '最初の求人を投稿しましょう',
                            style: TextStylePalette.subText,
                          ),
                          const SizedBox(height: SpacePalette.lg * 2),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/company-portal/jobs/post'),
                            icon: const Icon(Icons.add),
                            label: const Text('最初の求人を投稿'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final status = job['status'] as String? ?? 'closed';
                      final isOpen = status == 'open';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(SpacePalette.base),
                          title: Text(
                            job['title'] ?? '',
                            style: TextStylePalette.smListTitle,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: SpacePalette.xs),
                              Text(
                                job['salary'] ?? '',
                                style: TextStylePalette.normalText,
                              ),
                              const SizedBox(height: SpacePalette.xs),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: SpacePalette.sm,
                                      vertical: SpacePalette.xs / 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? ColorPalette.systemGreen.withOpacity(0.1)
                                          : ColorPalette.neutral200,
                                      borderRadius: BorderRadius.circular(RadiusPalette.mini),
                                    ),
                                    child: Text(
                                      isOpen ? '募集中' : '募集終了',
                                      style: TextStylePalette.miniTitle.copyWith(
                                        color: isOpen
                                            ? ColorPalette.systemGreen
                                            : ColorPalette.neutral500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: ColorPalette.neutral800,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: ColorPalette.neutral800,
                                    ),
                                    const SizedBox(width: SpacePalette.sm),
                                    Text(
                                      '編集',
                                      style: TextStylePalette.normalText,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: SpacePalette.sm),
                                    Text(
                                      '削除',
                                      style: TextStylePalette.normalText.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                context.go('/company-portal/jobs/${job['id']}/edit');
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      '削除確認',
                                      style: TextStylePalette.title,
                                    ),
                                    content: Text(
                                      'この求人を削除しますか？',
                                      style: TextStylePalette.normalText,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          'キャンセル',
                                          style: TextStylePalette.normalText.copyWith(
                                            color: ColorPalette.neutral500,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(
                                          '削除',
                                          style: TextStylePalette.normalText.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  try {
                                    await ref.read(companyPortalRepositoryProvider).deleteJob(job['id']);
                                    ref.invalidate(companyJobsProvider);
                                    ref.invalidate(dashboardStatsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '求人を削除しました',
                                            style: TextStylePalette.normalText.copyWith(
                                              color: ColorPalette.neutral0,
                                            ),
                                          ),
                                          backgroundColor: ColorPalette.systemGreen,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '削除エラー: $e',
                                            style: TextStylePalette.normalText.copyWith(
                                              color: ColorPalette.neutral0,
                                            ),
                                          ),
                                          backgroundColor: ColorPalette.primaryColor,
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
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
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: ColorPalette.primaryColor,
                      ),
                      const SizedBox(height: SpacePalette.lg),
                      Text(
                        'エラーが発生しました',
                        style: TextStylePalette.header,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        '$error',
                        style: TextStylePalette.subText,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}