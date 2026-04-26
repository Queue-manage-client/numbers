// auth/presentation/pages/company_signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';

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
    final agreedToTerms = useState(false);
    final agreedToPrivacy = useState(false);
    final agreedToContract = useState(false);

    Future<void> signup() async {
      if (!formKey.currentState!.validate()) return;

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードが一致しません')),
        );
        return;
      }

      if (!agreedToTerms.value || !agreedToPrivacy.value || !agreedToContract.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('すべての規約に同意してください')),
        );
        return;
      }

      isLoading.value = true;

      try {
        // 1. ユーザー作成（auth.users + profiles に 'user' で作成される）
        final authRepository = ref.read(authRepositoryProvider);
        final response = await authRepository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.user == null) {
          throw Exception('ユーザー作成に失敗しました');
        }

        // セッションが確立されているか確認
        // メールアドレスが既に登録済み、またはメール確認が必要な場合はセッションがnull
        if (response.session == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('このメールアドレスは既に登録されています。ログイン画面からお試しください。'),
              ),
            );
          }
          isLoading.value = false;
          return;
        }

        final userId = response.user!.id;

        // 2. 企業情報を companies テーブルに保存
        final companyPortalRepository = ref.read(companyPortalRepositoryProvider);
        final companyData = {
          'name': companyNameController.text.trim(),
          'representative_name': representativeNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'description': '', // 後で編集可能
          'address': '',
          'industry': '',
          'website': null,
        };

        final companyId = await companyPortalRepository.createCompany(companyData);

        // 3. profiles の role を 'company_user' に、company_id を設定
        await companyPortalRepository.updateUserProfile(
          userId: userId,
          role: 'company_user',
          companyId: companyId,
          position: '管理者', // デフォルト
        );

        // 4. 同意記録を保存（失敗しても登録は完了させる）
        try {
          final consentRepository = ref.read(consentRepositoryProvider);
          await consentRepository.saveConsentLogs(
            userId: userId,
            companyId: companyId,
            agreementTypes: ['terms', 'privacy', 'company_contract'],
            agreementVersion: 'v1.0',
          );
        } catch (_) {
          // 同意記録の保存失敗は致命的ではない
        }

        // 新規アカウント作成時にツアー閲覧履歴をリセット
        await AppTourService.resetAllTours();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('企業登録完了しました')),
          );

          // プロフィール情報を再取得
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(companyInfoProvider);

          context.go('/feed');
        }
      } catch (e) {
        if (context.mounted) {
          String errorMsg = '登録に失敗しました。';
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('already registered') || errStr.contains('already exists')) {
            errorMsg = 'このメールアドレスは既に登録されています。';
          } else if (errStr.contains('email')) {
            errorMsg = 'メールアドレスを確認してください。';
          } else if (errStr.contains('password')) {
            errorMsg = 'パスワードは6文字以上で入力してください。';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    decoration: InputDecoration(
                      hintText: '株式会社ABC',
                    ),
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
                    decoration: InputDecoration(
                      hintText: '山田太郎',
                    ),
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
                    decoration: InputDecoration(
                      hintText: '090-1234-5678',
                    ),
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
                    decoration: InputDecoration(
                      hintText: 'example@example.com',
                    ),
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
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '入力間違いはありませんか？',
                    ),
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
                  const SizedBox(height: SpacePalette.lg),

                  // 同意チェックボックス群
                  _buildAgreementCheckbox(
                    context: context,
                    value: agreedToTerms.value,
                    onChanged: (v) => agreedToTerms.value = v ?? false,
                    label: '利用規約',
                    onTapLink: () => context.push('/terms'),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  _buildAgreementCheckbox(
                    context: context,
                    value: agreedToPrivacy.value,
                    onChanged: (v) => agreedToPrivacy.value = v ?? false,
                    label: 'プライバシーポリシー',
                    onTapLink: () => context.push('/privacy'),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  _buildAgreementCheckbox(
                    context: context,
                    value: agreedToContract.value,
                    onChanged: (v) => agreedToContract.value = v ?? false,
                    label: '法人向け契約条項',
                    onTapLink: () => context.push('/company-portal/terms'),
                  ),
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

  Widget _buildAgreementCheckbox({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required VoidCallback onTapLink,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: ColorPalette.primaryColor,
          ),
        ),
        const SizedBox(width: SpacePalette.sm),
        Expanded(
          child: GestureDetector(
            onTap: onTapLink,
            child: Text(
              label,
              style: TextStylePalette.smSubText.copyWith(
                color: ColorPalette.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Text(
            'に同意する',
            style: TextStylePalette.smSubText,
          ),
        ),
      ],
    );
  }
}
