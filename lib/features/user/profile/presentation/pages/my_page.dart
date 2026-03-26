// profile/presentation/pages/my_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'マイページ',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: profileAsync.when(
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(SpacePalette.base),
            children: [
              // プロフィールカード
              Container(
                padding: const EdgeInsets.all(SpacePalette.base),
                decoration: BoxDecoration(
                  color: ColorPalette.neutral800,
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  border: Border.all(color: ColorPalette.neutral600),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'プロフィール',
                          style: TextStylePalette.smHeader,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile/edit'),
                          child: const Icon(
                            Icons.edit,
                            color: ColorPalette.neutral0,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacePalette.base),
                    _buildInfoRow('メール', user?.email ?? '未設定'),
                    _buildInfoRow('ニックネーム', profile?['nickname'] ?? '未設定'),
                    _buildInfoRow('性別', _getGenderText(profile?['gender'])),
                    _buildInfoRow('学歴', profile?['education'] ?? profile?['university'] ?? '未設定'),
                    _buildInfoRow('所在地', profile?['location'] ?? '未設定'),
                  ],
                ),
              ),
              const SizedBox(height: SpacePalette.base),

              // 職務経歴書カード
              Container(
                padding: const EdgeInsets.all(SpacePalette.base),
                decoration: BoxDecoration(
                  color: ColorPalette.neutral800,
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  border: Border.all(color: ColorPalette.neutral600),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '職務経歴書',
                      style: TextStylePalette.smHeader,
                    ),
                    const SizedBox(height: SpacePalette.sm),
                    if (profile?['resume_url'] != null && profile!['resume_url'].toString().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.description, color: ColorPalette.primaryColor, size: 20),
                          const SizedBox(width: SpacePalette.sm),
                          Expanded(
                            child: Text(
                              profile['resume_file_name'] ?? '職務経歴書',
                              style: TextStylePalette.normalText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'プロフィール編集から職務経歴書をアップロードできます',
                        style: TextStylePalette.subText,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: SpacePalette.base),

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
                        Icons.history,
                        color: ColorPalette.neutral0,
                      ),
                      title: Text(
                        '応募履歴',
                        style: TextStylePalette.normalText,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: ColorPalette.neutral400,
                      ),
                      onTap: () => context.push('/applications'),
                    ),
                    Divider(
                      height: 1,
                      color: ColorPalette.neutral600,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.settings,
                        color: ColorPalette.neutral0,
                      ),
                      title: Text(
                        '設定',
                        style: TextStylePalette.normalText,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: ColorPalette.neutral400,
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacePalette.base),

              // ログアウトカード
              GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: ColorPalette.neutral800,
                      title: Text('ログアウト', style: TextStylePalette.smTitle),
                      content: Text('ログアウトしますか？', style: TextStylePalette.normalText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('キャンセル', style: TextStyle(color: ColorPalette.neutral400)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('ログアウト'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    final repository = ref.read(authRepositoryProvider);
                    await repository.signOut();
                  } catch (_) {}
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral800,
                    borderRadius: BorderRadius.circular(RadiusPalette.lg),
                    border: Border.all(color: ColorPalette.neutral600),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: SpacePalette.sm),
                      Text(
                        'ログアウト',
                        style: TextStyle(
                          fontFamily: 'NotoSansJP',
                          color: Colors.red,
                          fontSize: FontSizePalette.size14,
                          fontVariations: const [FontVariation('wght', 700)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'エラー: $error',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStylePalette.subText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStylePalette.normalText,
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
