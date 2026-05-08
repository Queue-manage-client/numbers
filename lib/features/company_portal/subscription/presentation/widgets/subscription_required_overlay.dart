import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../providers/subscription_providers.dart';

class SubscriptionRequiredOverlay extends ConsumerWidget {
  const SubscriptionRequiredOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(currentCompanySubscriptionProvider).valueOrNull;
    final approved = sub?.isApproved ?? false;

    final headline = approved ? 'サブスクリプションが必要です' : 'アカウント審査中です';
    final body = approved
        ? (message ?? '投稿機能のご利用にはアクティブなサブスクリプションが必要です。')
        : '運営側の審査完了後、プランに加入することで投稿が可能になります。';

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/feed');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpacePalette.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: ColorPalette.primaryColor,
              ),
              const SizedBox(height: SpacePalette.base),
              Text(
                headline,
                style: TextStylePalette.smHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.inner),
              Text(
                body,
                style: TextStylePalette.subText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.lg),
              if (approved)
                SizedBox(
                  width: double.infinity,
                  height: ButtonSizePalette.button,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/company-portal/subscription/plans'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: ColorPalette.neutral900,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(RadiusPalette.base),
                      ),
                    ),
                    child: Text(
                      'プランを選択',
                      style: TextStylePalette.buttonTextDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
