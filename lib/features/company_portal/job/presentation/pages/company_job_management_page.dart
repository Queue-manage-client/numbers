// company_portal/job/presentation/pages/company_job_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/job/presentation/providers/company_job_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';


class CompanyJobManagementPage extends ConsumerWidget {
  const CompanyJobManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobListProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/feed'),
        ),
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
                            onPressed: () =>
                                context.go('/company-portal/jobs/post'),
                            icon: const Icon(Icons.add),
                            label: const Text('最初の求人を投稿'),
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
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final isOpen = job.status == 'open';

                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: SpacePalette.sm),
                          color: ColorPalette.neutral800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(RadiusPalette.base),
                            side: BorderSide(color: ColorPalette.neutral600),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(SpacePalette.base),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.title,
                                            style:
                                                TextStylePalette.smListTitle,
                                          ),
                                          const SizedBox(
                                              height: SpacePalette.xs),
                                          Text(
                                            job.salaryRangeDisplay.isNotEmpty
                                                ? job.salaryRangeDisplay
                                                : (job.salary ?? ''),
                                            style:
                                                TextStylePalette.normalText,
                                          ),
                                          if (job.location != null) ...[
                                            const SizedBox(
                                                height: SpacePalette.xs),
                                            Row(
                                              children: [
                                                Icon(Icons.place,
                                                    size: 14,
                                                    color: ColorPalette
                                                        .neutral400),
                                                const SizedBox(width: 4),
                                                Text(
                                                  job.location!,
                                                  style: TextStylePalette
                                                      .smText
                                                      .copyWith(
                                                          color: ColorPalette
                                                              .neutral400),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: ColorPalette.neutral400,
                                      ),
                                      color: ColorPalette.neutral800,
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'applications',
                                          child: Row(
                                            children: [
                                              Icon(Icons.people,
                                                  size: 20,
                                                  color: ColorPalette
                                                      .primaryColor),
                                              const SizedBox(
                                                  width: SpacePalette.sm),
                                              Text('申し込み一覧',
                                                  style: TextStylePalette
                                                      .normalText),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit,
                                                  size: 20,
                                                  color: ColorPalette
                                                      .neutral400),
                                              const SizedBox(
                                                  width: SpacePalette.sm),
                                              Text('編集',
                                                  style: TextStylePalette
                                                      .normalText),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete,
                                                  size: 20,
                                                  color: Colors.red),
                                              const SizedBox(
                                                  width: SpacePalette.sm),
                                              Text(
                                                '削除',
                                                style: TextStylePalette
                                                    .normalText
                                                    .copyWith(
                                                        color: Colors.red),
                                              ),
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
                                          _showDeleteDialog(
                                              context, ref, job.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: SpacePalette.sm),
                                // ステータスと申し込み数チップ
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: SpacePalette.sm,
                                        vertical: SpacePalette.xs / 2,
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
                                          vertical: SpacePalette.xs / 2,
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
                                                  color:
                                                      ColorPalette.neutral400),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // 申し込み数
                                    _ApplicationCountChips(jobId: job.id),
                                  ],
                                ),
                              ],
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('削除確認', style: TextStylePalette.title),
        content: Text('この求人を削除しますか？', style: TextStylePalette.normalText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル',
                style: TextStylePalette.normalText
                    .copyWith(color: ColorPalette.neutral500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier =
                  ref.read(companyJobNotifierProvider.notifier);
              final success = await notifier.delete(jobId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '求人を削除しました' : '削除に失敗しました',
                      style: TextStylePalette.normalText
                          .copyWith(color: ColorPalette.neutral0),
                    ),
                    backgroundColor:
                        success ? ColorPalette.systemGold : Colors.red,
                  ),
                );
              }
            },
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
  }
}

class _ApplicationCountChips extends ConsumerWidget {
  final String jobId;

  const _ApplicationCountChips({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(jobApplicationCountsProvider(jobId));

    return countsAsync.when(
      data: (counts) {
        final total = counts['total'] ?? 0;
        final pending = counts['pending'] ?? 0;
        final approved = counts['approved'] ?? 0;

        if (total == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChip('$total件', ColorPalette.neutral400),
            if (pending > 0) ...[
              const SizedBox(width: 4),
              _buildChip('審査中$pending', Colors.orange),
            ],
            if (approved > 0) ...[
              const SizedBox(width: 4),
              _buildChip('承認$approved', Colors.green),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: FontSizePalette.size12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
