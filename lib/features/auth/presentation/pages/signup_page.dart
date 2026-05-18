// auth/presentation/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/shared/utils/password_validator.dart';
import 'package:numbers/core/services/captcha_service.dart';
import 'package:numbers/shared/widgets/hcaptcha_widget.dart';

class SignupPage extends HookConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final captchaToken = useState<String?>(null);

    Future<void> signup() async {
      if (!formKey.currentState!.validate()) return;

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードが一致しません')),
        );
        return;
      }
      if (CaptchaService.isEnabled && captchaToken.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像認証を完了してください')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final repository = ref.read(authRepositoryProvider);
        final response = await repository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          captchaToken: captchaToken.value,
        );

        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 500));

          final user = repository.currentUser;
          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登録完了しました')),
            );
            context.go('/feed');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登録完了しました。ログインしてください。')),
            );
            context.go('/login');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登録エラー: $e')),
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
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '新規登録',
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
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
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
                  const SizedBox(height: SpacePalette.base),

                  // パスワード
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'パスワード',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: PasswordValidator.hint,
                    ),
                    obscureText: true,
                    validator: PasswordValidator.validate,
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // パスワード（確認）
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'パスワード（確認）',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      hintText: '入力間違いはありませんか？',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワード（確認）を入力してください';
                      }
                      if (value != passwordController.text) {
                        return 'パスワードが一致しません';
                      }
                      return null;
                    },
                  ),
                  if (CaptchaService.isEnabled) ...[
                    const SizedBox(height: SpacePalette.base),
                    HCaptchaWidget(
                      onVerified: (token) => captchaToken.value = token,
                    ),
                  ],
                  const SizedBox(height: SpacePalette.lg),

                  // 登録ボタン
                  GradientButton(
                    text: '登録',
                    onPressed: isLoading.value ? null : signup,
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
                  const SizedBox(height: SpacePalette.lg),

                  // ログインリンク
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'すでにアカウントをお持ちの方はこちら',
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
