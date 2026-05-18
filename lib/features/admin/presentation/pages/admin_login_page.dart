// admin/presentation/pages/admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/captcha_service.dart';
import 'package:numbers/shared/widgets/hcaptcha_widget.dart';

class AdminLoginPage extends HookConsumerWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final obscurePassword = useState(true);
    final captchaToken = useState<String?>(null);

    Future<void> login() async {
      if (!formKey.currentState!.validate()) return;
      if (CaptchaService.isEnabled && captchaToken.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像認証を完了してください')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
          captchaToken: captchaToken.value,
        );

        if (context.mounted) {
          // プロフィールを取得して管理者かどうかをチェック
          final profile = await ref.read(adminRepositoryProvider).getCurrentUserProfile();

          if (profile == null) {
            throw Exception('プロフィールが見つかりません');
          }

          final role = profile['role'] as String?;

          if (role != 'admin') {
            // 管理者ではない場合はログアウト
            await authRepository.signOut();
            throw Exception('管理者アカウントでログインしてください');
          }

          // 二段階認証ページへ。OTP の送信は遷移先で行う (セッション切れ復帰時も同じ経路)
          if (context.mounted) {
            context.go('/admin/otp-challenge');
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
      backgroundColor: ColorPalette.neutral900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 管理者アイコン
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: ColorPalette.primaryColor,
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // タイトル
                  Text(
                    '管理者ログイン',
                    style: TextStylePalette.header,
                    textAlign: TextAlign.center,
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
                      hintText: 'admin@example.com',
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
                    decoration: InputDecoration(
                      hintText: 'パスワードを入力',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
