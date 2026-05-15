// company_portal/presentation/pages/company_portal_select_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';


class CompanyPortalSelectPage extends StatelessWidget {
  final bool inShell;

  const CompanyPortalSelectPage({super.key, this.inShell = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: inShell
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
                onPressed: () => context.go('/feed'),
              ),
        title: const Text('管理メニュー'),
        backgroundColor: ColorPalette.neutral900,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SpacePalette.lg),
              Text(
                '管理する項目を選択してください',
                style: TextStylePalette.smHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.lg * 2),
              _SelectCard(
                icon: Icons.work_outline,
                title: '求人管理',
                subtitle: '求人の投稿・編集・申込確認を行います',
                onTap: () => context.go('/company-portal/jobs'),
              ),
              const SizedBox(height: SpacePalette.base),
              _SelectCard(
                icon: Icons.school_outlined,
                title: 'インターン管理',
                subtitle: 'インターンの投稿・編集・申込確認を行います',
                onTap: () => context.go('/company-portal/interns'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.neutral800,
      borderRadius: BorderRadius.circular(RadiusPalette.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        child: Container(
          padding: const EdgeInsets.all(SpacePalette.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusPalette.lg),
            border: Border.all(color: ColorPalette.neutral600),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                ),
                child: Icon(
                  icon,
                  color: ColorPalette.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: SpacePalette.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStylePalette.title),
                    const SizedBox(height: SpacePalette.xs),
                    Text(subtitle, style: TextStylePalette.subText),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorPalette.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
