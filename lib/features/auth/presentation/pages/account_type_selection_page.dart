// auth/presentation/pages/account_type_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AccountTypeSelectionPage extends HookWidget {
  const AccountTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base), // 全体padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '新規登録',
                  style: TextStylePalette.header,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacePalette.sm), // 付随項目の間隔
                Text(
                  'アカウントタイプを選択してください',
                  style: TextStylePalette.subText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacePalette.lg), // 別機能間隔（大きめ）

                // 個人用アカウントカード
                _AccountTypeCard(
                  title: '個人',
                  description: '求人情報の閲覧や応募、\n企業とのチャットができます',
                  onTap: () => context.go('/signup/individual'),
                ),

                const SizedBox(height: SpacePalette.sm),

                // 企業用アカウントカード
                _AccountTypeCard(
                  title: '企業',
                  description: '求人情報の掲載や\n応募者とのやりとりができます',
                  onTap: () => context.go('/signup/company'),
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
                      style: TextStylePalette.guide
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends HookWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base), // 全体padding
          child: Column(
            children: [
              Text(
                title,
                style: TextStylePalette.smListTitle
              ),
              const SizedBox(height: SpacePalette.sm), // 付随項目の間隔
              Text(
                description,
                style: TextStylePalette.smListLeading,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}