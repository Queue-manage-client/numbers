// company_portal/presentation/pages/company_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyLoginPage extends HookConsumerWidget {
  const CompanyLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);

    Future<void> login() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final repository = ref.read(authRepositoryProvider);
        await repository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (context.mounted) {
          // プロフィールを取得して企業アカウントかどうかをチェック
          final profile = await ref.read(companyPortalRepositoryProvider).getCurrentUserProfile();

          if (profile == null) {
            throw Exception('プロフィールが見つかりません');
          }

          final role = profile['role'] as String?;
          final companyId = profile['company_id'] as String?;

          if (role != 'company_user' || companyId == null) {
            // 企業アカウントではない場合はログアウト
            await repository.signOut();
            throw Exception('企業アカウントでログインしてください');
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ログインしました')),
            );
            context.go('/company-portal/dashboard');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ログインエラー: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base), // 全体padding
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  Text(
                    '企業ログイン',
                    style: TextStylePalette.header,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacePalette.lg), // 大きめの間隔

                  // メールアドレス
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      if (!value.contains('@')) {
                        return '有効なメールアドレスを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base), // 別機能間隔

                  // パスワード
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.lg), // 大きめの間隔

                  // ログインボタン
                  ElevatedButton(
                    onPressed: isLoading.value ? null : login,
                    child: isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : const Text('ログイン'),
                  ),
                  const SizedBox(height: SpacePalette.lg), // 大きめの間隔

                  // 企業アカウント登録リンク
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/signup/company');
                      },
                      child: Text(
                        '企業アカウント登録はこちら',
                        style: TextStylePalette.guide,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm), // 付随項目の間隔

                  // 個人アカウントリンク
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/login');
                      },
                      child: Text(
                        '個人アカウントはこちら',
                        style: TextStylePalette.guide,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}