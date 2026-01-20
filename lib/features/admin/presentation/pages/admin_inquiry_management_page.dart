// admin/presentation/pages/admin_inquiry_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminInquiryManagementPage extends HookConsumerWidget {
  const AdminInquiryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(adminInquiriesProvider);
    final filter = ref.watch(inquiryFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('問い合わせ管理'),
      ),
      body: Column(
        children: [
          // フィルターバー
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral0,
            child: Row(
              children: [
                Text('ステータス:', style: TextStylePalette.normalText),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: '全て',
                          isSelected: filter.status == null,
                          onTap: () {
                            ref.read(inquiryFilterProvider.notifier).state =
                                InquiryFilter();
                          },
                        ),
                        const SizedBox(width: SpacePalette.xs),
                        _FilterChip(
                          label: '未対応',
                          isSelected: filter.status == 'open',
                          color: Colors.red,
                          onTap: () {
                            ref.read(inquiryFilterProvider.notifier).state =
                                InquiryFilter(status: 'open');
                          },
                        ),
                        const SizedBox(width: SpacePalette.xs),
                        _FilterChip(
                          label: '対応中',
                          isSelected: filter.status == 'progress',
                          color: Colors.orange,
                          onTap: () {
                            ref.read(inquiryFilterProvider.notifier).state =
                                InquiryFilter(status: 'progress');
                          },
                        ),
                        const SizedBox(width: SpacePalette.xs),
                        _FilterChip(
                          label: '解決済み',
                          isSelected: filter.status == 'resolved',
                          color: Colors.green,
                          onTap: () {
                            ref.read(inquiryFilterProvider.notifier).state =
                                InquiryFilter(status: 'resolved');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 問い合わせリスト
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminInquiriesProvider);
              },
              child: inquiriesAsync.when(
                data: (inquiries) {
                  if (inquiries.isEmpty) {
                    return Center(
                      child: Text(
                        '問い合わせが見つかりません',
                        style: TextStylePalette.subText,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    itemCount: inquiries.length,
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      return _InquiryCard(
                        inquiry: inquiry,
                        onTap: () {
                          context.go('/admin/inquiries/${inquiry['id']}');
                        },
                      );
                    },
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
                    style: TextStylePalette.subText,
                  ),
                ),
              ),
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
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? ColorPalette.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: SpacePalette.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : ColorPalette.neutral200,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.normalText.copyWith(
            color: isSelected ? ColorPalette.neutral0 : ColorPalette.neutral800,
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final Map<String, dynamic> inquiry;
  final VoidCallback onTap;

  const _InquiryCard({
    required this.inquiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = inquiry['status'] ?? 'open';
    final profile = inquiry['profiles'] as Map<String, dynamic>?;
    final createdAt = inquiry['created_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inquiry['subject'] ?? '件名なし',
                      style: TextStylePalette.smListTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: SpacePalette.xs),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: ColorPalette.neutral500,
                  ),
                  const SizedBox(width: SpacePalette.xs),
                  Text(
                    profile?['nickname'] ?? '不明なユーザー',
                    style: TextStylePalette.subText,
                  ),
                  const Spacer(),
                  if (createdAt != null)
                    Text(
                      _formatDate(createdAt),
                      style: TextStylePalette.subText.copyWith(fontSize: 12),
                    ),
                ],
              ),
              if (inquiry['message'] != null) ...[
                const SizedBox(height: SpacePalette.xs),
                Text(
                  inquiry['message'],
                  style: TextStylePalette.subText.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 'open':
        label = '未対応';
        color = Colors.red;
        break;
      case 'progress':
        label = '対応中';
        color = Colors.orange;
        break;
      case 'resolved':
        label = '解決済み';
        color = Colors.green;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStylePalette.subText.copyWith(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
