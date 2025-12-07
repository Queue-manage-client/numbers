// auth/presentation/pages/company_signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanySignupPage extends HookConsumerWidget {
  const CompanySignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final companyNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final representativeNameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final isLoading = useState(false);

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

        final response = await repository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 500));

          final user = repository.currentUser;
          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('企業登録完了しました')),
            );
            context.go('/company-portal/dashboard');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登録完了しました。ログインしてください。')),
            );
            context.go('/company-portal/login');
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
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral100,
        foregroundColor: ColorPalette.neutral800,
        title: Text(
          '企業アカウント登録',
          style: TextStylePalette.title,
        ),
      ),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '企業名',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  // 企業名
                  TextFormField(
                    controller: companyNameController,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '企業名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base), // 別機能間隔

                  // 代表者名
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '代表者名',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: representativeNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '代表者名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 電話番号
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '電話番号',
                      style: TextStylePalette.smTitle,
                    ),
                  ),
                  SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '電話番号を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

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
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワード（確認）を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base), // 別機能間隔

                  // 登録ボタン
                  ElevatedButton(
                    onPressed: isLoading.value ? null : signup,
                    child: isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : const Text('登録'),
                  ),
                  const SizedBox(height: SpacePalette.lg), // 別機能間隔
                  
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: (){
                        context.go('/company-portal/login');
                      },
                      child: Text(
                        'すでに企業アカウントをお持ちの方はこちら',
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