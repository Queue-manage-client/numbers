// profile/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/my-page');
            }
          },
        ),
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

          // ツアーカード
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.neutral800,
              borderRadius: BorderRadius.circular(RadiusPalette.lg),
              border: Border.all(color: ColorPalette.neutral600),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: ColorPalette.neutral0,
              ),
              title: Text(
                '操作ガイドを再表示',
                style: TextStylePalette.normalText,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: ColorPalette.neutral400,
              ),
              onTap: () async {
                await AppTourService.resetAllTours();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ホームに戻ると操作ガイドが表示されます')),
                  );
                }
              },
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
                  onTap: () => context.push('/terms'),
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
                  onTap: () => context.push('/privacy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
