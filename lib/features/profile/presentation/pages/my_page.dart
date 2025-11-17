import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: profileAsync.when(
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'プロフィール',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('メール', user?.email ?? '未設定'),
                      _buildInfoRow(
                          'ニックネーム', profile?['nickname'] ?? '未設定'),
                      _buildInfoRow('性別', _getGenderText(profile?['gender'])),
                      _buildInfoRow('大学', profile?['university'] ?? '未設定'),
                      _buildInfoRow('所在地', profile?['location'] ?? '未設定'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.push('/profile/edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF323232),
                            foregroundColor: const Color(0xFFFFFFFF),
                          ),
                          child: const Text('プロフィール編集'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.history, color: Color(0xFF323232)),
                      title: const Text('応募履歴'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/applications'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.settings, color: Color(0xFF323232)),
                      title: const Text('設定'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF323232),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'male':
        return '男性';
      case 'female':
        return '女性';
      case 'other':
        return 'その他';
      default:
        return '未設定';
    }
  }
}
