// admin/presentation/pages/admin_consent_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminConsentManagementPage extends HookConsumerWidget {
  const AdminConsentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminConsentLogsProvider);
    final filter = ref.watch(consentFilterProvider);
    final companiesAsync = ref.watch(adminCompaniesProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('同意記録管理'),
      ),
      body: Column(
        children: [
          // フィルターバー
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral800,
            child: Column(
              children: [
                // 規約タイプフィルター
                Row(
                  children: [
                    Text('規約:', style: TextStylePalette.normalText),
                    const SizedBox(width: SpacePalette.sm),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: '全て',
                              isSelected: filter.agreementType == null,
                              onTap: () {
                                ref.read(consentFilterProvider.notifier).state =
                                    ConsentFilter(companyId: filter.companyId);
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: '利用規約',
                              isSelected: filter.agreementType == 'terms',
                              onTap: () {
                                ref.read(consentFilterProvider.notifier).state =
                                    ConsentFilter(agreementType: 'terms', companyId: filter.companyId);
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: 'プライバシー',
                              isSelected: filter.agreementType == 'privacy',
                              onTap: () {
                                ref.read(consentFilterProvider.notifier).state =
                                    ConsentFilter(agreementType: 'privacy', companyId: filter.companyId);
                              },
                            ),
                            const SizedBox(width: SpacePalette.xs),
                            _FilterChip(
                              label: '法人契約',
                              isSelected: filter.agreementType == 'company_contract',
                              onTap: () {
                                ref.read(consentFilterProvider.notifier).state =
                                    ConsentFilter(agreementType: 'company_contract', companyId: filter.companyId);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacePalette.sm),
                // 企業フィルター
                companiesAsync.when(
                  data: (companies) => Row(
                    children: [
                      Text('企業:', style: TextStylePalette.normalText),
                      const SizedBox(width: SpacePalette.sm),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: filter.companyId,
                          dropdownColor: ColorPalette.neutral600,
                          style: TextStylePalette.normalText,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ColorPalette.neutral600,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.sm,
                              vertical: SpacePalette.xs,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('全企業'),
                            ),
                            ...companies.map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['name'] as String? ?? ''),
                            )),
                          ],
                          onChanged: (value) {
                            ref.read(consentFilterProvider.notifier).state =
                                ConsentFilter(agreementType: filter.agreementType, companyId: value);
                          },
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // 一覧
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      '同意記録がありません',
                      style: TextStylePalette.subText,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminConsentLogsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.sm),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _ConsentLogCard(log: log);
                    },
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'エラー: $error',
                  style: TextStylePalette.subText.copyWith(
                    color: ColorPalette.primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // ページネーション
          Container(
            padding: const EdgeInsets.all(SpacePalette.sm),
            color: ColorPalette.neutral800,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: ColorPalette.neutral0),
                  onPressed: filter.page > 0
                      ? () {
                          ref.read(consentFilterProvider.notifier).state =
                              filter.copyWith(page: filter.page - 1);
                        }
                      : null,
                ),
                Text(
                  '${filter.page + 1} ページ',
                  style: TextStylePalette.normalText,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: ColorPalette.neutral0),
                  onPressed: logsAsync.when(
                    data: (logs) => logs.length >= 20 ? () {
                      ref.read(consentFilterProvider.notifier).state =
                          filter.copyWith(page: filter.page + 1);
                    } : null,
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentLogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _ConsentLogCard({required this.log});

  String _agreementTypeLabel(String type) {
    switch (type) {
      case 'terms':
        return '利用規約';
      case 'privacy':
        return 'プライバシーポリシー';
      case 'company_contract':
        return '法人向け契約条項';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = log['profiles'] as Map<String, dynamic>?;
    final companies = log['companies'] as Map<String, dynamic>?;
    final acceptedAt = log['accepted_at'] as String?;
    final agreementType = log['agreement_type'] as String? ?? '';
    final agreementVersion = log['agreement_version'] as String? ?? '';
    final ipAddress = log['ip_address'] as String? ?? '不明';
    final deviceInfo = log['device_info'] as Map<String, dynamic>?;

    final userName = profiles?['nickname'] as String? ?? '不明';
    final companyName = companies?['name'] as String? ?? '-';

    String formattedDate = '';
    if (acceptedAt != null) {
      final dt = DateTime.tryParse(acceptedAt)?.toLocal();
      if (dt != null) {
        formattedDate = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    String deviceSummary = '不明';
    if (deviceInfo != null) {
      final platform = deviceInfo['platform'] as String? ?? '';
      final model = deviceInfo['model'] as String?;
      final osVersion = deviceInfo['os_version'] as String?;
      final browser = deviceInfo['browser'] as String?;
      if (platform == 'web') {
        deviceSummary = 'Web (${browser ?? "不明"})';
      } else if (model != null) {
        deviceSummary = '$model (${osVersion ?? platform})';
      } else {
        deviceSummary = platform;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacePalette.sm,
                    vertical: SpacePalette.xs,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(RadiusPalette.mini),
                  ),
                  child: Text(
                    _agreementTypeLabel(agreementType),
                    style: TextStylePalette.subText.copyWith(
                      color: ColorPalette.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Text(
                  agreementVersion,
                  style: TextStylePalette.subText.copyWith(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStylePalette.subText.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: SpacePalette.sm),
            // 詳細行
            _DetailRow(label: 'ユーザー', value: userName),
            _DetailRow(label: '企業', value: companyName),
            _DetailRow(label: 'IP', value: ipAddress),
            _DetailRow(label: '端末', value: deviceSummary),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStylePalette.subText.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStylePalette.normalText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: SpacePalette.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral600,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.subText.copyWith(
            color: isSelected ? ColorPalette.neutral0 : ColorPalette.neutral300,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
