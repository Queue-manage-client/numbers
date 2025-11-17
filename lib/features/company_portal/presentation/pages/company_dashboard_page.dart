import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final companyInfoAsync = ref.watch(companyInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: companyInfoAsync.when(
          data: (company) => Text(company?['name'] ?? '企業ポータル'),
          loading: () => const Text('企業ポータル'),
          error: (_, __) => const Text('企業ポータル'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final repository = ref.read(authRepositoryProvider);
              await repository.signOut();
              if (context.mounted) {
                context.go('/company-portal/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ダッシュボード',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 24),

            // 統計情報カード
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.video_library,
                          title: '動画',
                          count: '${stats['videos'] ?? 0}',
                          color: const Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.work,
                          title: '求人',
                          count: '${stats['jobs'] ?? 0}',
                          color: const Color(0xFF323232),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.school,
                          title: 'インターン',
                          count: '${stats['internships'] ?? 0}',
                          color: const Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.chat,
                          title: 'チャット',
                          count: '${stats['chats'] ?? 0}',
                          color: const Color(0xFF323232),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF323232))),
              error: (error, _) => Center(
                child: Text('エラー: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 32),

            // メニューグリッド
            const Text(
              'メニュー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 16),

            _MenuCard(
              icon: Icons.video_library,
              title: '動画管理',
              description: '企業紹介動画の投稿・編集',
              onTap: () => context.go('/company-portal/videos'),
            ),
            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.work,
              title: '求人管理',
              description: '求人情報の掲載・管理',
              onTap: () => context.go('/company-portal/jobs'),
            ),
            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.school,
              title: 'インターン管理',
              description: 'インターンシップ情報の管理',
              onTap: () => context.go('/company-portal/interns'),
            ),
            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.chat,
              title: 'チャット管理',
              description: '応募者とのチャット',
              onTap: () => context.go('/company-portal/chats'),
            ),
            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.business,
              title: '企業情報編集',
              description: '企業プロフィールの編集',
              onTap: () => context.go('/company-portal/profile/edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF323232),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF323232),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF323232),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: const Color(0xFF323232)),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF323232),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF323232)),
            ],
          ),
        ),
      ),
    );
  }
}
