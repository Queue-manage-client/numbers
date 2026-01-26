// profile/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '設定',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: ListView(
        padding: const EdgeInsets.all(SpacePalette.base),
        children: [
          // メニューカード
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: ColorPalette.neutral600),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock,
                    color: ColorPalette.neutral0,
                  ),
                  title: Text(
                    'パスワード変更',
                    style: TextStylePalette.normalText,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ColorPalette.neutral400,
                  ),
                  onTap: () => context.push('/password-reset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacePalette.base),

          // 規約カード
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: ColorPalette.neutral600),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: ColorPalette.neutral0,
                  ),
                  title: Text(
                    '利用規約',
                    style: TextStylePalette.normalText,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ColorPalette.neutral400,
                  ),
                  onTap: () {
                    // TODO: 利用規約ページへ遷移
                  },
                ),
                Divider(
                  height: 1,
                  color: ColorPalette.neutral600,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip,
                    color: ColorPalette.neutral0,
                  ),
                  title: Text(
                    'プライバシーポリシー',
                    style: TextStylePalette.normalText,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ColorPalette.neutral400,
                  ),
                  onTap: () {
                    // TODO: プライバシーポリシーページへ遷移
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacePalette.base),

          // ログアウトカード
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: ColorPalette.neutral600),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'ログアウト',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final repository = ref.read(authRepositoryProvider);
                await repository.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
