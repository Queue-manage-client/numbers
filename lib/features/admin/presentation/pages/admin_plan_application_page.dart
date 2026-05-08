import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/admin_plan_application_repository.dart';
import '../../providers/admin_plan_application_provider.dart';

class AdminPlanApplicationPage extends ConsumerWidget {
  const AdminPlanApplicationPage({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    AdminPlanApplicationRow row,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('承認しますか？', style: TextStylePalette.smHeader),
        content: Text(
          '${row.companyName ?? row.companyId} の '
          '${row.requestedPlanCode} 申請を承認します。',
          style: TextStylePalette.normalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル', style: TextStylePalette.subText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              foregroundColor: ColorPalette.neutral900,
            ),
            child: Text('承認', style: TextStylePalette.buttonTextDark),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(adminPlanApplicationRepositoryProvider)
          .approve(row.id);
      ref.invalidate(adminPlanApplicationsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('承認しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('承認に失敗しました: $e')),
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    AdminPlanApplicationRow row,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('却下理由', style: TextStylePalette.smHeader),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStylePalette.normalText,
          cursorColor: ColorPalette.primaryColor,
          decoration: InputDecoration(
            hintText: '却下理由を入力',
            hintStyle: TextStylePalette.hintText,
            filled: true,
            fillColor: ColorPalette.neutral900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusPalette.base),
              borderSide: const BorderSide(color: ColorPalette.neutral600),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusPalette.base),
              borderSide: const BorderSide(color: ColorPalette.neutral600),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusPalette.base),
              borderSide:
                  const BorderSide(color: ColorPalette.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('キャンセル', style: TextStylePalette.subText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: ColorPalette.neutral0,
            ),
            child: Text('却下', style: TextStylePalette.buttonTextLight),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    try {
      await ref
          .read(adminPlanApplicationRepositoryProvider)
          .reject(row.id, reason);
      ref.invalidate(adminPlanApplicationsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('却下しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('却下に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(adminPlanApplicationsProvider);
    final filter = ref.watch(adminPlanApplicationFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('プラン申請審査'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral800,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '審査中',
                    isSelected: filter == 'pending',
                    color: Colors.orange,
                    onTap: () => ref
                        .read(adminPlanApplicationFilterProvider.notifier)
                        .state = 'pending',
                  ),
                  const SizedBox(width: SpacePalette.sm),
                  _FilterChip(
                    label: '承認済み',
                    isSelected: filter == 'approved',
                    color: ColorPalette.primaryColor,
                    onTap: () => ref
                        .read(adminPlanApplicationFilterProvider.notifier)
                        .state = 'approved',
                  ),
                  const SizedBox(width: SpacePalette.sm),
                  _FilterChip(
                    label: '却下',
                    isSelected: filter == 'rejected',
                    color: Colors.redAccent,
                    onTap: () => ref
                        .read(adminPlanApplicationFilterProvider.notifier)
                        .state = 'rejected',
                  ),
                  const SizedBox(width: SpacePalette.sm),
                  _FilterChip(
                    label: 'すべて',
                    isSelected: filter == null,
                    onTap: () => ref
                        .read(adminPlanApplicationFilterProvider.notifier)
                        .state = null,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: applicationsAsync.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Text('申請はありません',
                        style: TextStylePalette.subText),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: SpacePalette.sm),
                  itemBuilder: (_, i) => _ApplicationCard(
                    row: rows[i],
                    onApprove: () => _approve(context, ref, rows[i]),
                    onReject: () => _reject(context, ref, rows[i]),
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
              error: (e, _) => Center(
                child: Text('読み込み失敗: $e',
                    style: TextStylePalette.subText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? ColorPalette.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.base,
          vertical: SpacePalette.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? base : ColorPalette.neutral900,
          border: Border.all(color: base),
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.smTitle.copyWith(
            color: isSelected ? ColorPalette.neutral900 : base,
          ),
        ),
      ),
    );
  }
}

class _EvidenceImage extends StatefulWidget {
  const _EvidenceImage({required this.storagePath});
  final String storagePath;

  @override
  State<_EvidenceImage> createState() => _EvidenceImageState();
}

class _EvidenceImageState extends State<_EvidenceImage> {
  Future<String>? _signedUrlFuture;

  @override
  void initState() {
    super.initState();
    _signedUrlFuture = Supabase.instance.client.storage
        .from('plan-evidence')
        .createSignedUrl(widget.storagePath, 60 * 10);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _signedUrlFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorPalette.primaryColor,
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Text(
            'エビデンス取得失敗: ${snap.error ?? widget.storagePath}',
            style: TextStylePalette.smSubText
                .copyWith(color: Colors.redAccent),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(RadiusPalette.mini),
          child: Image.network(
            snap.data!,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              'エビデンス画像が表示できません',
              style: TextStylePalette.smSubText
                  .copyWith(color: Colors.redAccent),
            ),
          ),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final AdminPlanApplicationRow row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _statusColor() => switch (row.status) {
        'approved' => ColorPalette.primaryColor,
        'rejected' => Colors.redAccent,
        _ => Colors.orange,
      };

  String _statusLabel() => switch (row.status) {
        'approved' => '承認済み',
        'rejected' => '却下',
        _ => '審査中',
      };

  @override
  Widget build(BuildContext context) {
    final isPending = row.status == 'pending';
    final statusColor = _statusColor();
    return Container(
      padding: const EdgeInsets.all(SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  row.companyName ?? row.companyId,
                  style: TextStylePalette.bigText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacePalette.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(RadiusPalette.mini),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStylePalette.miniTitle.copyWith(
                    color: ColorPalette.neutral900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacePalette.sm),
          Text('申請プラン: ${row.requestedPlanCode}',
              style: TextStylePalette.normalText),
          Text('申請日: ${_formatDate(row.createdAt)}',
              style: TextStylePalette.subText),
          if (row.applicantNote != null && row.applicantNote!.isNotEmpty) ...[
            const SizedBox(height: SpacePalette.sm),
            Text('備考: ${row.applicantNote}',
                style: TextStylePalette.subText),
          ],
          if (row.evidenceUrl != null) ...[
            const SizedBox(height: SpacePalette.sm),
            _EvidenceImage(storagePath: row.evidenceUrl!),
          ],
          if (row.rejectionReason != null) ...[
            const SizedBox(height: SpacePalette.sm),
            Text('却下理由: ${row.rejectionReason}',
                style: TextStylePalette.smSubText
                    .copyWith(color: Colors.redAccent)),
          ],
          if (isPending) ...[
            const SizedBox(height: SpacePalette.inner),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: ButtonSizePalette.innerButton,
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(RadiusPalette.base),
                        ),
                      ),
                      child:
                          Text('却下', style: TextStylePalette.smTitle.copyWith(color: Colors.redAccent)),
                    ),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: SizedBox(
                    height: ButtonSizePalette.innerButton,
                    child: ElevatedButton(
                      onPressed: onApprove,
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
                        '承認',
                        style: TextStylePalette.buttonTextDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}年${local.month}月${local.day}日';
  }
}
