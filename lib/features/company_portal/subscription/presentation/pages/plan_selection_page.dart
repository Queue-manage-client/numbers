import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_providers.dart';

class PlanSelectionPage extends ConsumerStatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  ConsumerState<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends ConsumerState<PlanSelectionPage>
    with WidgetsBindingObserver {
  BillingCycle _cycle = BillingCycle.monthly;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  String _formatYen(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '¥$buf';
  }

  Future<void> _startCheckout(SubscriptionPlan plan) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final url = await repo.createCheckoutSessionUrl(
        planCode: plan.code,
        billingCycle: _cycle,
      );
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('ブラウザを起動できませんでした');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加入処理に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);
    final sub = ref.watch(currentCompanySubscriptionProvider).valueOrNull;

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
              context.go('/company-portal/subscription');
            }
          },
        ),
        title: Text('プラン選択', style: TextStylePalette.title),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Text('利用可能なプランがありません',
                  style: TextStylePalette.subText),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(SpacePalette.base),
            children: [
              _CycleSelector(
                cycle: _cycle,
                onChanged: (c) => setState(() => _cycle = c),
              ),
              const SizedBox(height: SpacePalette.base),
              ...plans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  cycle: _cycle,
                  isCurrent: sub?.currentPlanCode == plan.code &&
                      sub?.currentBillingCycle == _cycle.apiValue,
                  busy: _busy,
                  formatYen: _formatYen,
                  onSubscribe: () => _startCheckout(plan),
                ),
              ),
              const SizedBox(height: SpacePalette.lg),
              Center(
                child: TextButton(
                  onPressed: () => context
                      .push('/company-portal/subscription/applications'),
                  child: Text(
                    '商工会・特別プランを申請する',
                    style: TextStylePalette.guide,
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
}

class _CycleSelector extends StatelessWidget {
  const _CycleSelector({required this.cycle, required this.onChanged});

  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacePalette.xs),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Row(
        children: [
          for (final c in BillingCycle.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  height: ButtonSizePalette.filter,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cycle == c
                        ? ColorPalette.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(RadiusPalette.mini),
                  ),
                  child: Text(
                    c.label,
                    style: cycle == c
                        ? TextStylePalette.smTitle.copyWith(
                            color: ColorPalette.neutral900,
                          )
                        : TextStylePalette.subText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.isCurrent,
    required this.busy,
    required this.formatYen,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final BillingCycle cycle;
  final bool isCurrent;
  final bool busy;
  final String Function(int) formatYen;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final amount = cycle == BillingCycle.monthly
        ? plan.monthlyAmount
        : plan.yearlyAmount;
    final available = amount != null;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.inner),
      padding: const EdgeInsets.all(SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        border: Border.all(
          color: isCurrent
              ? ColorPalette.primaryColor
              : ColorPalette.neutral600,
          width: isCurrent ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name, style: TextStylePalette.bigText),
              const SizedBox(width: SpacePalette.sm),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacePalette.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColor,
                    borderRadius: BorderRadius.circular(RadiusPalette.mini),
                  ),
                  child: Text(
                    '加入中',
                    style: TextStylePalette.miniTitle.copyWith(
                      color: ColorPalette.neutral900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            available ? formatYen(amount) : '準備中',
            style: TextStylePalette.smHeader.copyWith(
              color: ColorPalette.primaryColor,
            ),
          ),
          if (available)
            Padding(
              padding: const EdgeInsets.only(top: SpacePalette.xs),
              child: Text(
                '${cycle.label}（税込）',
                style: TextStylePalette.smSubText,
              ),
            ),
          const SizedBox(height: SpacePalette.base),
          SizedBox(
            width: double.infinity,
            height: ButtonSizePalette.innerButton,
            child: ElevatedButton(
              onPressed:
                  (available && !busy && !isCurrent) ? onSubscribe : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColor,
                foregroundColor: ColorPalette.neutral900,
                disabledBackgroundColor: ColorPalette.neutral600,
                disabledForegroundColor: ColorPalette.neutral400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                ),
              ),
              child: Text(
                isCurrent ? '加入中' : '加入する',
                style: TextStylePalette.smTitle.copyWith(
                  color: isCurrent
                      ? ColorPalette.neutral400
                      : ColorPalette.neutral900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
