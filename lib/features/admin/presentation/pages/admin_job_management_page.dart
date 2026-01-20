// admin/presentation/pages/admin_job_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminJobManagementPage extends HookConsumerWidget {
  const AdminJobManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider);
    final companiesAsync = ref.watch(adminCompaniesProvider);
    final filter = ref.watch(jobFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('求人管理'),
      ),
      body: Column(
        children: [
          // フィルターバー
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral0,
            child: Column(
              children: [
                // 企業フィルター
                companiesAsync.when(
                  data: (companies) => DropdownButtonFormField<String?>(
                    value: filter.companyId,
                    decoration: const InputDecoration(
                      labelText: '企業でフィルター',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全ての企業')),
                      ...companies.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] ?? '不明'),
                          )),
                    ],
                    onChanged: (value) {
                      ref.read(jobFilterProvider.notifier).state =
                          JobFilter(companyId: value, status: filter.status);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('企業の読み込みエラー'),
                ),
                const SizedBox(height: SpacePalette.sm),
                // ステータスフィルター
                Row(
                  children: [
                    Text('ステータス:', style: TextStylePalette.normalText),
                    const SizedBox(width: SpacePalette.sm),
                    _FilterChip(
                      label: '全て',
                      isSelected: filter.status == null,
                      onTap: () {
                        ref.read(jobFilterProvider.notifier).state =
                            JobFilter(companyId: filter.companyId);
                      },
                    ),
                    const SizedBox(width: SpacePalette.xs),
                    _FilterChip(
                      label: '公開中',
                      isSelected: filter.status == 'open',
                      onTap: () {
                        ref.read(jobFilterProvider.notifier).state =
                            JobFilter(companyId: filter.companyId, status: 'open');
                      },
                    ),
                    const SizedBox(width: SpacePalette.xs),
                    _FilterChip(
                      label: '締切',
                      isSelected: filter.status == 'closed',
                      onTap: () {
                        ref.read(jobFilterProvider.notifier).state =
                            JobFilter(companyId: filter.companyId, status: 'closed');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 求人リスト
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminJobsProvider);
              },
              child: jobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Center(
                      child: Text(
                        '求人が見つかりません',
                        style: TextStylePalette.subText,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _JobCard(
                        job: job,
                        onToggleStatus: () async {
                          final isOpen = job['status'] == 'open';
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            await repo.updateJobStatus(
                              job['id'],
                              isOpen ? 'closed' : 'open',
                            );
                            ref.invalidate(adminJobsProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isOpen ? '求人を締め切りました' : '求人を公開しました',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('エラー: $e')),
                              );
                            }
                          }
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('削除確認'),
                              content: const Text('この求人を削除しますか？この操作は元に戻せません。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('削除'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              final repo = ref.read(adminRepositoryProvider);
                              await repo.deleteJob(job['id']);
                              ref.invalidate(adminJobsProvider);
                              ref.invalidate(adminDashboardStatsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('求人を削除しました')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('エラー: $e')),
                                );
                              }
                            }
                          }
                        },
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
                  child: Text(
                    'エラー: $error',
                    style: TextStylePalette.subText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: SpacePalette.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral200,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.normalText.copyWith(
            color: isSelected ? ColorPalette.neutral0 : ColorPalette.neutral800,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _JobCard({
    required this.job,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = job['status'] == 'open';
    final company = job['companies'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOpen
                    ? ColorPalette.primaryColor.withOpacity(0.1)
                    : ColorPalette.neutral200,
                borderRadius: BorderRadius.circular(RadiusPalette.mini),
              ),
              child: Icon(
                Icons.work,
                color: isOpen ? ColorPalette.primaryColor : ColorPalette.neutral500,
              ),
            ),
            const SizedBox(width: SpacePalette.base),

            // 求人情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job['title'] ?? '無題',
                          style: TextStylePalette.smListTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(isOpen: isOpen),
                    ],
                  ),
                  const SizedBox(height: SpacePalette.xs),
                  Text(
                    '企業: ${company?['name'] ?? '不明'}',
                    style: TextStylePalette.subText,
                  ),
                  Row(
                    children: [
                      if (job['location'] != null)
                        Text(
                          '${job['location']}',
                          style: TextStylePalette.subText.copyWith(fontSize: 12),
                        ),
                      if (job['salary'] != null) ...[
                        const Text(' | '),
                        Text(
                          '${job['salary']}',
                          style: TextStylePalette.subText.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // アクションメニュー
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  onToggleStatus();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isOpen ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: SpacePalette.sm),
                      Text(isOpen ? '締め切る' : '公開する'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: SpacePalette.sm),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;

  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(
          color: isOpen
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Text(
        isOpen ? '公開中' : '締切',
        style: TextStylePalette.subText.copyWith(
          fontSize: 10,
          color: isOpen ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
