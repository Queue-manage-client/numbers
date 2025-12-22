// profile/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF323232)),
            title: const Text('パスワード変更'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/password-reset'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF323232)),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 利用規約ページへ遷移
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF323232)),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: プライバシーポリシーページへ遷移
            },
          ),
          const Divider(),
          ListTile(
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
        ],
      ),
    );
  }
}
