// auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    // 入力コントローラー定義
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    // ローディングフラグ
    final isLoading = useState(false);
    final obscurePassword = useState(true);

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
          // ログイン成功後、profileのroleを取得して適切な画面へ遷移
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser?.id;

          if (userId != null) {
            final profile = await supabase
                .from('profiles')
                .select('role')
                .eq('id', userId)
                .maybeSingle();

            final role = profile?['role'] as String?;

            if (context.mounted) {
              if (role == 'admin') {
                context.go('/admin/dashboard');
              } else if (role == 'company_user') {
                context.go('/company-portal/dashboard');
              } else {
                context.go('/feed');
              }
            }
          } else {
            context.go('/feed');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メールアドレスまたはパスワードが正しくありません')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
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
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'ようこそ',
                      style: TextStylePalette.header,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // メールアドレス
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'メールアドレス',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'example@example.com',
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'パスワード',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: '6文字以上で入力してください',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                          color: ColorPalette.neutral400,
                        ),
                        onPressed: () => obscurePassword.value = !obscurePassword.value,
                      ),
                    ),
                    obscureText: obscurePassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください';
                      }
                      if (value.length < 6) {
                        return 'パスワードは6文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.lg), // 別機能間隔

                  // ログインボタン
                  GradientButton(
                    text: 'ログイン',
                    onPressed: isLoading.value ? null : login,
                    isLoading: isLoading.value,
                    icon: Transform.rotate(
                      angle: -0.5,
                      child: const Icon(
                        Icons.send,
                        color: ColorPalette.neutral0,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg), // 別機能間隔

                  // パスワードを忘れた方
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: (){
                        context.go('/password-reset');
                      },
                      child: Text(
                        'パスワードを忘れた方はこちら',
                        style: TextStylePalette.guide
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm), // 付随項目の間隔

                  // 新規登録リンク
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: (){
                        context.go('/signup');
                      },
                      child: Text(
                        'アカウントをお持ちでない方はこちら',
                        style: TextStylePalette.guide
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