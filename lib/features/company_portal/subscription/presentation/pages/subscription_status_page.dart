import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../providers/subscription_providers.dart';
import 'checkout_webview_page.dart';


class SubscriptionStatusPage extends ConsumerStatefulWidget {
  const SubscriptionStatusPage({super.key});

  @override
  ConsumerState<SubscriptionStatusPage> createState() =>
      _SubscriptionStatusPageState();
}

class _SubscriptionStatusPageState
    extends ConsumerState<SubscriptionStatusPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(currentCompanySubscriptionProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(currentCompanySubscriptionProvider);
    }
  }

  Future<void> _openPortal(BuildContext context) async {
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final url = await repo.createPortalSessionUrl();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StripeWebViewPage(
            url: url,
            title: 'プラン管理',
          ),
        ),
      );
      if (mounted) ref.invalidate(currentCompanySubscriptionProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プラン管理画面を開けませんでした: $e')),
      );
    }
  }

  String _statusLabel(String? status) => switch (status) {
        'active' => '加入中',
        'trialing' => 'トライアル中',
        'past_due' => '支払い失敗（要対応）',
        'canceled' => '解約済み',
        'incomplete' => '加入処理中',
        'unpaid' => '未払い',
        _ => '未加入',
      };

  Color _statusColor(String? status) => switch (status) {
        'active' || 'trialing' => ColorPalette.primaryColor,
        'past_due' || 'unpaid' => Colors.orange,
        'canceled' => ColorPalette.neutral400,
        _ => ColorPalette.neutral400,
      };

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(currentCompanySubscriptionProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => _handleBack(context),
        ),
        title: Text('サブスクリプション', style: TextStylePalette.title),
      ),
      body: subAsync.when(
        data: (sub) {
          if (sub == null) {
            return Center(
              child: Text('企業情報が見つかりません', style: TextStylePalette.subText),
            );
          }
          final hasSub = sub.subscriptionStatus != null &&
              sub.subscriptionStatus != 'canceled';
          return ListView(
            padding: const EdgeInsets.all(SpacePalette.base),
            children: [
              _StatusCard(
                title: 'ステータス',
                value: _statusLabel(sub.subscriptionStatus),
                valueColor: _statusColor(sub.subscriptionStatus),
              ),
              if (sub.currentPlanCode != null)
                _StatusCard(
                  title: 'プラン',
                  value: sub.currentPlanCode!,
                ),
              if (sub.currentPeriodEnd != null)
                _StatusCard(
                  title: '次回更新日',
                  value: _formatDate(sub.currentPeriodEnd!),
                ),
              if (sub.cancelAtPeriodEnd)
                _StatusCard(
                  title: '解約予定',
                  value: '次回更新日に解約されます',
                  valueColor: Colors.orange,
                ),
              const SizedBox(height: SpacePalette.lg),
              SizedBox(
                width: double.infinity,
                height: ButtonSizePalette.button,
                child: ElevatedButton(
                  onPressed: hasSub
                      ? () => _openPortal(context)
                      : () => context.push('/company-portal/subscription/plans'),
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
                    hasSub ? 'プラン管理 / 解約 / 領収書' : 'プランに加入する',
                    style: TextStylePalette.buttonTextDark,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text('読み込みに失敗しました: $e', style: TextStylePalette.subText),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}年${local.month}月${local.day}日';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      padding: const EdgeInsets.all(SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStylePalette.subText),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStylePalette.smTitle.copyWith(
                color: valueColor ?? ColorPalette.neutral0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
