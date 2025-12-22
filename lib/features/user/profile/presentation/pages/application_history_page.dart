// profile/presentation/pages/application_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class ApplicationHistoryPage extends ConsumerWidget {
  const ApplicationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('応募履歴'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return const Center(
              child: Text('応募履歴がありません'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final job = application['jobs'] as Map<String, dynamic>?;
              final company = job?['companies'] as Map<String, dynamic>?;
              final status = application['status'] as String?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    job?['title'] ?? '求人名未設定',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF323232),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(company?['name'] ?? '企業名未設定'),
                      const SizedBox(height: 4),
                      _buildStatusChip(status),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/applications/${application['id']}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String text;

    switch (status) {
      case 'applied':
        color = Colors.blue;
        text = '応募済み';
        break;
      case 'messaging':
        color = Colors.orange;
        text = 'メッセージ中';
        break;
      case 'accepted':
        color = Colors.green;
        text = '採用';
        break;
      case 'rejected':
        color = Colors.red;
        text = '不採用';
        break;
      default:
        color = Colors.grey;
        text = '不明';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
