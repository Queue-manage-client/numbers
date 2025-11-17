import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyJobManagementPage extends ConsumerWidget {
  const CompanyJobManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('求人管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/jobs/list'),
                    icon: const Icon(Icons.list),
                    label: const Text('求人一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF323232),
                      side: const BorderSide(color: Color(0xFF323232)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              '投稿済み求人',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 16),
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
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '投稿済みの求人はありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/company-portal/jobs/post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF323232),
                              foregroundColor: const Color(0xFFFFFFFF),
                            ),
                            child: const Text('最初の求人を投稿'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF323232),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            job['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF323232),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['salary'] ?? '',
                                style: const TextStyle(color: Color(0xFF323232)),
                              ),
                              Text(
                                'ステータス: ${job['status'] == 'open' ? '募集中' : '募集終了'}',
                                style: TextStyle(
                                  color: job['status'] == 'open' ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF323232)),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('編集'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('削除'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                context.go('/company-portal/jobs/${job['id']}/edit');
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('削除確認'),
                                    content: const Text('この求人を削除しますか?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('削除', style: TextStyle(color: Colors.red)),
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
                                        const SnackBar(content: Text('求人を削除しました')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('削除エラー: $e')),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF323232)),
                ),
                error: (error, _) => Center(
                  child: Text('エラー: $error', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
