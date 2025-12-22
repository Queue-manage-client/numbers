// company/presentation/pages/company_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class CompanyDetailPage extends ConsumerWidget {
  const CompanyDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final companyAsync = ref.watch(companyProvider(companyId));
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('企業詳細'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: companyAsync.when(
        data: (company) {
          if (company == null) {
            return const Center(child: Text('企業が見つかりません'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company['name'] ?? '企業名未設定',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        company['industry'] ?? '業種未設定',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        company['description'] ?? '説明未設定',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(context, '動画', '/company/$companyId/videos'),
                      _buildSection(context, '求人', '/company/$companyId/jobs'),
                      _buildSection(
                          context, 'インターン', '/company/$companyId/interns'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
