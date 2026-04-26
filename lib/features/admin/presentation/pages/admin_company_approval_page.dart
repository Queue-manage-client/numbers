// admin/presentation/pages/admin_company_approval_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/domain/models/company.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminCompanyApprovalPage extends HookConsumerWidget {
  const AdminCompanyApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(adminCompanyApprovalsProvider);
    final filter = ref.watch(companyApprovalFilterProvider);
    final searchController = useTextEditingController();

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('企業審査管理'),
      ),
      body: Column(
        children: [
          // フィルターエリア
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral800,
            child: Column(
              children: [
                // 検索バー
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '企業名で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              ref.read(companyApprovalFilterProvider.notifier).state =
                                  CompanyApprovalFilter(
                                    approvalStatus: filter.approvalStatus,
                                  );
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) {
                    ref.read(companyApprovalFilterProvider.notifier).state =
                        CompanyApprovalFilter(
                          approvalStatus: filter.approvalStatus,
                          searchQuery: value.isNotEmpty ? value : null,
                        );
                  },
                ),
                const SizedBox(height: SpacePalette.sm),

                // ステータスフィルター
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'すべて',
                        isSelected: filter.approvalStatus == null,
                        onTap: () {
                          ref.read(companyApprovalFilterProvider.notifier).state =
                              CompanyApprovalFilter(searchQuery: filter.searchQuery);
                        },
                      ),
                      const SizedBox(width: SpacePalette.sm),
                      _FilterChip(
                        label: '審査待ち',
                        isSelected: filter.approvalStatus == 'pending',
                        color: Colors.orange,
                        onTap: () {
                          ref.read(companyApprovalFilterProvider.notifier).state =
                              CompanyApprovalFilter(
                                approvalStatus: 'pending',
                                searchQuery: filter.searchQuery,
                              );
                        },
                      ),
                      const SizedBox(width: SpacePalette.sm),
                      _FilterChip(
                        label: '審査通過',
                        isSelected: filter.approvalStatus == 'approved',
                        color: ColorPalette.primaryColor,
                        onTap: () {
                          ref.read(companyApprovalFilterProvider.notifier).state =
                              CompanyApprovalFilter(
                                approvalStatus: 'approved',
                                searchQuery: filter.searchQuery,
                              );
                        },
                      ),
                      const SizedBox(width: SpacePalette.sm),
                      _FilterChip(
                        label: '審査否認',
                        isSelected: filter.approvalStatus == 'rejected',
                        color: Colors.red,
                        onTap: () {
                          ref.read(companyApprovalFilterProvider.notifier).state =
                              CompanyApprovalFilter(
                                approvalStatus: 'rejected',
                                searchQuery: filter.searchQuery,
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 企業一覧
          Expanded(
            child: companiesAsync.when(
              data: (companies) {
                if (companies.isEmpty) {
                  return Center(
                    child: Text(
                      '該当する企業がありません',
                      style: TextStylePalette.subText,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminCompanyApprovalsProvider);
                    ref.invalidate(pendingCompanyCountProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final companyData = companies[index];
                      final company = Company.fromJson(companyData);
                      return _CompanyApprovalCard(
                        company: company,
                        onApprove: () => _showApprovalDialog(context, ref, company, 'approved'),
                        onReject: () => _showApprovalDialog(context, ref, company, 'rejected'),
                      );
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('エラー: $error', style: TextStylePalette.normalText),
                    const SizedBox(height: SpacePalette.base),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminCompanyApprovalsProvider),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    Company company,
    String newStatus,
  ) {
    final noteController = TextEditingController();
    final isApproval = newStatus == 'approved';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text(
          isApproval ? '審査通過の確認' : '審査否認の確認',
          style: TextStylePalette.smHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '企業名: ${company.name}',
              style: TextStylePalette.normalText,
            ),
            if (company.representativeName != null) ...[
              const SizedBox(height: SpacePalette.xs),
              Text(
                '代表者: ${company.representativeName}',
                style: TextStylePalette.subText,
              ),
            ],
            const SizedBox(height: SpacePalette.base),
            Text(
              isApproval
                  ? 'この企業を承認しますか？承認後、企業ポータルの全機能が利用可能になります。'
                  : 'この企業を否認しますか？否認理由を入力してください。',
              style: TextStylePalette.normalText,
            ),
            const SizedBox(height: SpacePalette.base),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isApproval ? 'メモ（任意）' : '否認理由を入力',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: ColorPalette.neutral400),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final repository = ref.read(adminRepositoryProvider);
                await repository.updateCompanyApprovalStatus(
                  companyId: company.id,
                  status: newStatus,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                );

                ref.invalidate(adminCompanyApprovalsProvider);
                ref.invalidate(pendingCompanyCountProvider);
                ref.invalidate(adminDashboardStatsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isApproval
                            ? '${company.name} を承認しました'
                            : '${company.name} を否認しました',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? ColorPalette.primaryColor : Colors.red,
            ),
            child: Text(
              isApproval ? '承認する' : '否認する',
              style: const TextStyle(color: ColorPalette.neutral0),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyApprovalCard extends StatelessWidget {
  final Company company;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _CompanyApprovalCard({
    required this.company,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: 企業名 + ステータス
            Row(
              children: [
                Expanded(
                  child: Text(
                    company.name,
                    style: TextStylePalette.smListTitle,
                  ),
                ),
                _buildStatusChip(company.approvalStatus),
              ],
            ),
            const SizedBox(height: SpacePalette.sm),

            // 企業情報
            if (company.representativeName != null)
              _infoRow(Icons.person, '代表者: ${company.representativeName}'),
            if (company.phone != null)
              _infoRow(Icons.phone, company.phone!),
            if (company.industry != null && company.industry!.isNotEmpty)
              _infoRow(Icons.business, company.industry!),

            // 審査メモ
            if (company.approvalNote != null && company.approvalNote!.isNotEmpty) ...[
              const SizedBox(height: SpacePalette.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacePalette.sm),
                decoration: BoxDecoration(
                  color: ColorPalette.neutral900,
                  borderRadius: BorderRadius.circular(RadiusPalette.mini),
                ),
                child: Text(
                  'メモ: ${company.approvalNote}',
                  style: TextStylePalette.subText,
                ),
              ),
            ],

            // 審査日時
            if (company.reviewedAt != null) ...[
              const SizedBox(height: SpacePalette.xs),
              Text(
                '審査日: ${_formatDate(company.reviewedAt!)}',
                style: TextStylePalette.subText.copyWith(fontSize: FontSizePalette.size12),
              ),
            ],

            const SizedBox(height: SpacePalette.base),

            // アクションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (company.approvalStatus != CompanyApprovalStatus.approved)
                  TextButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('承認'),
                    style: TextButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                    ),
                  ),
                if (company.approvalStatus != CompanyApprovalStatus.rejected) ...[
                  const SizedBox(width: SpacePalette.sm),
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('否認'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CompanyApprovalStatus status) {
    final Color color;
    switch (status) {
      case CompanyApprovalStatus.pending:
        color = Colors.orange;
      case CompanyApprovalStatus.approved:
        color = ColorPalette.primaryColor;
      case CompanyApprovalStatus.rejected:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.sm,
        vertical: SpacePalette.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: FontSizePalette.size12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorPalette.neutral400),
          const SizedBox(width: SpacePalette.sm),
          Expanded(
            child: Text(
              text,
              style: TextStylePalette.subText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? ColorPalette.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.base,
          vertical: SpacePalette.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusPalette.lg),
          border: Border.all(
            color: isSelected ? chipColor : ColorPalette.neutral600,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : ColorPalette.neutral400,
            fontSize: FontSizePalette.size14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
