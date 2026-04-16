// auth/presentation/pages/individual_signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/router/app_router.dart' show pendingWelcomeGuide;

class IndividualSignupPage extends HookConsumerWidget {
  const IndividualSignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final agreedToTerms = useState(false);

    Future<void> signup() async {
      if (!formKey.currentState!.validate()) return;

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードが一致しません')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final repository = ref.read(authRepositoryProvider);

        // 登録成功後にウェルカムガイドへリダイレクトさせるフラグ
        pendingWelcomeGuide = true;

        await repository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          nickname: nameController.text.trim(),
        );

        if (context.mounted) {
          final user = repository.currentUser;
          if (user != null) {
            // authNotifierのredirectが/welcome-guideへ飛ばす
            // 念のため明示的にも遷移
            context.go('/welcome-guide');
          } else {
            pendingWelcomeGuide = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登録完了しました。ログインしてください。')),
            );
            context.go('/login');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登録に失敗しました。入力内容をご確認ください。')),
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '個人として登録',
                      style: TextStylePalette.header,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // 名前
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '名前',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: '山田太郎',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '名前を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base), // 別機能間隔

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
                    ),
                    obscureText: true,
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
                  const SizedBox(height: SpacePalette.base), // 別機能間隔

                  // パスワード確認
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'パスワード（確認）',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
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
                  const SizedBox(height: SpacePalette.base),

                  // 利用規約同意チェックボックス
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: agreedToTerms.value,
                          onChanged: (v) => agreedToTerms.value = v ?? false,
                          activeColor: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(width: SpacePalette.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => agreedToTerms.value = !agreedToTerms.value,
                          child: Text.rich(
                            TextSpan(
                              style: TextStylePalette.smSubText,
                              children: [
                                const TextSpan(text: '私は、'),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.push('/terms'),
                                    child: Text(
                                      '利用規約',
                                      style: TextStylePalette.smSubText.copyWith(
                                        color: ColorPalette.primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' および '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.push('/privacy'),
                                    child: Text(
                                      'プライバシーポリシー',
                                      style: TextStylePalette.smSubText.copyWith(
                                        color: ColorPalette.primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' を確認し、これらに同意します。'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // 登録ボタン
                  GradientButton(
                    text: '登録',
                    onPressed: isLoading.value ? null : () {
                      if (!agreedToTerms.value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('利用規約とプライバシーポリシーに同意してください')),
                        );
                        return;
                      }
                      signup();
                    },
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
                        'すでにアカウントをお持ちの方はこちら',
                        style: TextStylePalette.guide,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}