// intern/presentation/pages/intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class InternListPage extends ConsumerWidget {
  const InternListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipsAsync = ref.watch(internshipsProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('インターン一覧'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: internshipsAsync.when(
        data: (internships) {
          if (internships.isEmpty) {
            return const Center(child: Text('インターンがありません'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final internship = internships[index];
              final company = internship['companies'] as Map<String, dynamic>?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    internship['title'] ?? 'タイトル未設定',
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
                      Text(
                        '期間: ${internship['start_date'] ?? '未定'} 〜 ${internship['end_date'] ?? '未定'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/interns/${internship['id']}'),
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
}
