// job/presentation/pages/job_application_complete_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobApplicationCompletePage extends StatelessWidget {
  const JobApplicationCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('応募完了'),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: ColorPalette.systemGold,
              ),
              const SizedBox(height: SpacePalette.lg),
              Text(
                '応募が完了しました',
                style: TextStylePalette.lgListTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.base),
              Text(
                '企業が承認するとチャットで\nやり取りできるようになります。',
                style: TextStylePalette.subText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.lg * 2),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'ホームに戻る',
                  onPressed: () => context.go('/feed'),
                ),
              ),
              const SizedBox(height: SpacePalette.base),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/applications'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.primaryColor,
                    side: const BorderSide(color: ColorPalette.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
                  ),
                  child: const Text('応募履歴を見る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
