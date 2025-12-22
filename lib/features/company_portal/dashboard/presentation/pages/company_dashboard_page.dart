// features/company_portal/dashboard/presentation/pages/company_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyDashboardPage extends HookConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ===== デバッグコード =====
    useEffect(() {
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      
      print('=== 認証状態確認（ダッシュボード） ===');
      print('User ID: ${user?.id}');
      print('Email: ${user?.email}');
      print('Logged in: ${user != null}');
      print('Session exists: ${session != null}');
      print('Session expires at: ${session?.expiresAt}');
      print('==================');
      
      // profilesテーブルの確認
      if (user != null) {
        ref.read(currentUserProfileProvider.future).then((profile) {
          print('=== プロフィール情報 ===');
          print('Profile: $profile');
          print('Role: ${profile?['role']}');
          print('Company ID: ${profile?['company_id']}');
          print('==================');
        }).catchError((error) {
          print('=== プロフィール取得エラー ===');
          print('Error: $error');
          print('==================');
        });
      }
      
      return null;
    }, []);
    // ===== デバッグコード終了 =====
    
    final statsAsync = ref.watch(dashboardStatsProvider);
    final companyInfoAsync = ref.watch(companyInfoProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        title: companyInfoAsync.when(
          data: (company) => Text(company?['name'] ?? '企業ポータル'),
          loading: () => const Text('企業ポータル'),
          error: (_, __) => const Text('企業ポータル'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: ColorPalette.neutral800,
            ),
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
                          icon: Icons.video_library,
                          title: '動画',
                          count: '${stats['videos'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: SpacePalette.base),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.work,
                          title: '求人',
                          count: '${stats['jobs'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacePalette.base),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.school,
                          title: 'インターン',
                          count: '${stats['internships'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: SpacePalette.base),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.chat,
                          title: 'チャット',
                          count: '${stats['chats'] ?? 0}',
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

            // メニューグリッド
            Text(
              'メニュー',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),

            _MenuCard(
              icon: Icons.video_library,
              title: '動画管理',
              description: '企業紹介動画の投稿・編集',
              onTap: () => context.go('/company-portal/videos'),
            ),
            const SizedBox(height: SpacePalette.sm),

            _MenuCard(
              icon: Icons.work,
              title: '求人管理',
              description: '求人情報の掲載・管理',
              onTap: () => context.go('/company-portal/jobs'),
            ),
            const SizedBox(height: SpacePalette.sm),

            _MenuCard(
              icon: Icons.school,
              title: 'インターン管理',
              description: 'インターンシップ情報の管理',
              onTap: () => context.go('/company-portal/interns'),
            ),
            const SizedBox(height: SpacePalette.sm),

            _MenuCard(
              icon: Icons.chat,
              title: 'チャット管理',
              description: '応募者とのチャット',
              onTap: () => context.go('/company-portal/chats'),
            ),
            const SizedBox(height: SpacePalette.sm),

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

  const _StatCard({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: ColorPalette.primaryColor,
            ),
            const SizedBox(height: SpacePalette.sm),
            Text(
              count,
              style: TextStylePalette.header.copyWith(
                color: ColorPalette.primaryColor,
              ),
            ),
            const SizedBox(height: SpacePalette.xs),
            Text(
              title,
              style: TextStylePalette.normalText,
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