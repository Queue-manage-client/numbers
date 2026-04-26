// admin/presentation/pages/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminDashboardPage extends HookConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final pendingCountAsync = ref.watch(pendingCompanyCountProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: ColorPalette.neutral0,
            ),
            onPressed: () async {
              final repository = ref.read(authRepositoryProvider);
              await repository.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(pendingCompanyCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ダッシュボード',
                style: TextStylePalette.header,
              ),
              const SizedBox(height: SpacePalette.lg),

              // 統計情報カード
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people,
                            title: 'ユーザー',
                            count: '${stats['users'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: SpacePalette.sm),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.business,
                            title: '企業',
                            count: '${stats['companies'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: SpacePalette.sm),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.video_library,
                            title: '動画',
                            count: '${stats['videos'] ?? 0}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacePalette.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.work,
                            title: '求人',
                            count: '${stats['jobs'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: SpacePalette.sm),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.school,
                            title: 'インターン',
                            count: '${stats['internships'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: SpacePalette.sm),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.mail,
                            title: '未対応',
                            count: '${stats['openInquiries'] ?? 0}',
                            isHighlighted: (stats['openInquiries'] ?? 0) > 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: ColorPalette.primaryColor,
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'エラー: $error',
                    style: TextStylePalette.subText.copyWith(
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg * 2),

              // 審査待ち企業通知
              pendingCountAsync.when(
                data: (count) {
                  if (count > 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: SpacePalette.base),
                      padding: const EdgeInsets.all(SpacePalette.base),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/admin/company-approvals'),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                            const SizedBox(width: SpacePalette.base),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '審査待ちの企業があります',
                                    style: TextStylePalette.smListTitle.copyWith(
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    '$count件の企業が審査を待っています',
                                    style: TextStylePalette.subText,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.orange),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // メニューグリッド
              Text(
                '管理メニュー',
                style: TextStylePalette.smHeader,
              ),
              const SizedBox(height: SpacePalette.base),

              _MenuCard(
                icon: Icons.verified_user,
                title: '企業審査管理',
                description: '法人アカウントの審査・承認・否認',
                onTap: () => context.go('/admin/company-approvals'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.people,
                title: 'ユーザー管理',
                description: 'ユーザーアカウントの管理・停止',
                onTap: () => context.go('/admin/users'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.video_library,
                title: '動画管理',
                description: '企業動画のモデレーション',
                onTap: () => context.go('/admin/videos'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.work,
                title: '求人管理',
                description: '求人情報の管理',
                onTap: () => context.go('/admin/jobs'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.school,
                title: 'インターン管理',
                description: 'インターンシップ情報の管理',
                onTap: () => context.go('/admin/interns'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.mail,
                title: '問い合わせ管理',
                description: 'ユーザーからの問い合わせ対応',
                onTap: () => context.go('/admin/inquiries'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.featured_play_list,
                title: 'フィード管理',
                description: 'バナー・特集セクションの管理',
                onTap: () => context.go('/admin/feed'),
              ),
              const SizedBox(height: SpacePalette.sm),

              _MenuCard(
                icon: Icons.verified_user,
                title: '同意記録管理',
                description: '法人登録時の規約同意記録の確認',
                onTap: () => context.go('/admin/consents'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final bool isHighlighted;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.count,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? ColorPalette.primaryColor.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.sm),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isHighlighted ? ColorPalette.primaryColor : ColorPalette.neutral0,
            ),
            const SizedBox(height: SpacePalette.xs),
            Text(
              count,
              style: TextStylePalette.smHeader.copyWith(
                color: isHighlighted ? ColorPalette.primaryColor : ColorPalette.neutral0,
              ),
            ),
            const SizedBox(height: SpacePalette.xs),
            Text(
              title,
              style: TextStylePalette.subText.copyWith(
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: ColorPalette.primaryColor,
              ),
              const SizedBox(width: SpacePalette.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStylePalette.smListTitle,
                    ),
                    const SizedBox(height: SpacePalette.xs),
                    Text(
                      description,
                      style: TextStylePalette.subText,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorPalette.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
