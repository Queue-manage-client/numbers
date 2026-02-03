// auth/presentation/pages/password_reset_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class PasswordResetPage extends HookConsumerWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final isLoading = useState(false);

    Future<void> sendResetEmail() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final supabase = ref.read(supabaseClientProvider);
        await supabase.auth.resetPasswordForEmail(emailController.text.trim());

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('パスワードリセットメールを送信しました')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
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
                  Text(
                    'パスワードリセット',
                    style: TextStylePalette.header,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacePalette.base), // 別機能間隔
                  Text(
                    '登録したメールアドレスを入力してください。\nパスワードリセット用のリンクを送信します。',
                    style: TextStylePalette.smSubText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacePalette.lg), // 別機能間隔（大きめ）
                  
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
                  
                  GradientButton(
                    text: 'リセットメールを送信',
                    onPressed: isLoading.value ? null : sendResetEmail,
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
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: (){
                        context.go('/login');
                      },
                      child: Text(
                        'ログイン画面に戻る',
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