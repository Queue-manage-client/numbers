// company_portal/job/presentation/pages/company_job_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/job/presentation/providers/company_job_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyJobListManagementPage extends ConsumerWidget {
  const CompanyJobListManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobListProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/jobs'),
        ),
        title: const Text('求人一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/company-portal/jobs/post'),
          ),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: ColorPalette.neutral400,
                  ),
                  const SizedBox(height: SpacePalette.base),
                  Text(
                    '投稿済みの求人はありません',
                    style: TextStylePalette.subText,
                  ),
                  const SizedBox(height: SpacePalette.lg),
                  ElevatedButton(
                    onPressed: () => context.go('/company-portal/jobs/post'),
                    child: const Text('最初の求人を投稿'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyJobListProvider);
            },
            color: ColorPalette.primaryColor,
            backgroundColor: ColorPalette.neutral800,
            child: ListView.builder(
              padding: const EdgeInsets.all(SpacePalette.base),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isOpen = job.status == 'open';

                return Card(
                  margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                  color: ColorPalette.neutral800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                    side: BorderSide(color: ColorPalette.neutral600),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(SpacePalette.base),
                    title: Text(
                      job.title,
                      style: TextStylePalette.smListTitle,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: SpacePalette.xs),
                        if (job.description.isNotEmpty)
                          Text(
                            job.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStylePalette.smText
                                .copyWith(color: ColorPalette.neutral400),
                          ),
                        const SizedBox(height: SpacePalette.sm),
                        Row(
                          children: [
                            if (job.location != null) ...[
                              Icon(Icons.place,
                                  size: 16,
                                  color: ColorPalette.neutral400),
                              const SizedBox(width: 4),
                              Text(
                                job.location!,
                                style: TextStylePalette.smText
                                    .copyWith(color: ColorPalette.neutral400),
                              ),
                              const SizedBox(width: SpacePalette.base),
                            ],
                            if (job.salaryRangeDisplay.isNotEmpty) ...[
                              Icon(Icons.payments,
                                  size: 16,
                                  color: ColorPalette.neutral400),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  job.salaryRangeDisplay,
                                  style: TextStylePalette.smText
                                      .copyWith(color: ColorPalette.neutral400),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacePalette.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? ColorPalette.systemGold
                                        .withOpacity(0.1)
                                    : ColorPalette.neutral600
                                        .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(
                                    RadiusPalette.mini),
                              ),
                              child: Text(
                                isOpen ? '募集中' : '募集終了',
                                style:
                                    TextStylePalette.miniTitle.copyWith(
                                  color: isOpen
                                      ? ColorPalette.systemGold
                                      : ColorPalette.neutral500,
                                ),
                              ),
                            ),
                            if (job.jobCategory != null) ...[
                              const SizedBox(width: SpacePalette.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacePalette.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorPalette.neutral600
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(
                                      RadiusPalette.mini),
                                ),
                                child: Text(
                                  job.jobCategory!,
                                  style: TextStylePalette.miniTitle
                                      .copyWith(
                                          color: ColorPalette.neutral400),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: Icon(Icons.more_vert,
                          color: ColorPalette.neutral400),
                      color: ColorPalette.neutral800,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'applications',
                          child: Row(
                            children: [
                              Icon(Icons.people,
                                  size: 20,
                                  color: ColorPalette.primaryColor),
                              const SizedBox(width: SpacePalette.sm),
                              Text('申し込み一覧',
                                  style: TextStylePalette.normalText),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 20,
                                  color: ColorPalette.neutral400),
                              const SizedBox(width: SpacePalette.sm),
                              Text('編集',
                                  style: TextStylePalette.normalText),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              const SizedBox(width: SpacePalette.sm),
                              Text('削除',
                                  style: TextStylePalette.normalText
                                      .copyWith(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'applications') {
                          context.push(
                              '/company-portal/jobs/${job.id}/applications');
                        } else if (value == 'edit') {
                          context.go(
                              '/company-portal/jobs/${job.id}/edit');
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: ColorPalette.neutral800,
                              title: Text('削除確認',
                                  style: TextStylePalette.title),
                              content: Text('この求人を削除しますか？',
                                  style: TextStylePalette.normalText),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('キャンセル',
                                      style: TextStylePalette.normalText
                                          .copyWith(
                                              color: ColorPalette
                                                  .neutral500)),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: Text('削除',
                                      style: TextStylePalette.normalText
                                          .copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            final notifier = ref
                                .read(companyJobNotifierProvider.notifier);
                            final success =
                                await notifier.delete(job.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '求人を削除しました'
                                        : '削除に失敗しました',
                                    style: TextStylePalette.normalText
                                        .copyWith(
                                            color: ColorPalette.neutral0),
                                  ),
                                  backgroundColor: success
                                      ? ColorPalette.systemGold
                                      : Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
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
              Icon(Icons.error_outline,
                  size: 48, color: ColorPalette.primaryColor),
              const SizedBox(height: SpacePalette.base),
              Text('エラーが発生しました',
                  style: TextStylePalette.normalText),
              const SizedBox(height: SpacePalette.sm),
              TextButton(
                onPressed: () => ref.invalidate(companyJobListProvider),
                child: Text('再読み込み',
                    style: TextStyle(color: ColorPalette.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
