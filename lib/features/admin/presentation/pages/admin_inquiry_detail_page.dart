// admin/presentation/pages/admin_inquiry_detail_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminInquiryDetailPage extends HookConsumerWidget {
  final String inquiryId;

  const AdminInquiryDetailPage({
    super.key,
    required this.inquiryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiryAsync = ref.watch(adminInquiryByIdProvider(inquiryId));

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/inquiries'),
        ),
        title: const Text('問い合わせ詳細'),
      ),
      body: inquiryAsync.when(
        data: (inquiry) {
          if (inquiry == null) {
            return Center(
              child: Text(
                '問い合わせが見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          final status = inquiry['status'] ?? 'open';
          final profile = inquiry['profiles'] as Map<String, dynamic>?;
          final createdAt = inquiry['created_at'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ステータスカード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ステータス',
                          style: TextStylePalette.smTitle,
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        _StatusSelector(
                          currentStatus: status,
                          onStatusChanged: (newStatus) async {
                            try {
                              final repo = ref.read(adminRepositoryProvider);
                              await repo.updateInquiryStatus(inquiryId, newStatus);
                              ref.invalidate(adminInquiryByIdProvider(inquiryId));
                              ref.invalidate(adminInquiriesProvider);
                              ref.invalidate(adminDashboardStatsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ステータスを更新しました')),
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SpacePalette.base),

                // ユーザー情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ユーザー情報',
                          style: TextStylePalette.smTitle,
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  ColorPalette.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: ColorPalette.primaryColor,
                              ),
                            ),
                            const SizedBox(width: SpacePalette.base),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?['nickname'] ?? '不明なユーザー',
                                    style: TextStylePalette.smListTitle,
                                  ),
                                  Text(
                                    'ID: ${profile?['id']?.substring(0, 8) ?? '不明'}...',
                                    style: TextStylePalette.subText.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SpacePalette.base),

                // 問い合わせ内容カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '問い合わせ内容',
                                style: TextStylePalette.smTitle,
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: TextStylePalette.subText.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: SpacePalette.base),
                        Text(
                          '件名',
                          style: TextStylePalette.subText,
                        ),
                        const SizedBox(height: SpacePalette.xs),
                        Text(
                          inquiry['subject'] ?? '件名なし',
                          style: TextStylePalette.smListTitle,
                        ),
                        const SizedBox(height: SpacePalette.base),
                        Text(
                          '本文',
                          style: TextStylePalette.subText,
                        ),
                        const SizedBox(height: SpacePalette.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(SpacePalette.base),
                          decoration: BoxDecoration(
                            color: ColorPalette.neutral100,
                            borderRadius: BorderRadius.circular(RadiusPalette.base),
                          ),
                          child: Text(
                            inquiry['message'] ?? '本文なし',
                            style: TextStylePalette.normalText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
            style: TextStylePalette.subText,
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class _StatusSelector extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChanged;

  const _StatusSelector({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusButton(
          label: '未対応',
          status: 'open',
          currentStatus: currentStatus,
          color: Colors.red,
          onTap: () => onStatusChanged('open'),
        ),
        const SizedBox(width: SpacePalette.sm),
        _StatusButton(
          label: '対応中',
          status: 'progress',
          currentStatus: currentStatus,
          color: Colors.orange,
          onTap: () => onStatusChanged('progress'),
        ),
        const SizedBox(width: SpacePalette.sm),
        _StatusButton(
          label: '解決済み',
          status: 'resolved',
          currentStatus: currentStatus,
          color: Colors.green,
          onTap: () => onStatusChanged('resolved'),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final String status;
  final String currentStatus;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = status == currentStatus;

    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: SpacePalette.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            border: Border.all(
              color: color.withOpacity(isSelected ? 1 : 0.5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStylePalette.normalText.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
