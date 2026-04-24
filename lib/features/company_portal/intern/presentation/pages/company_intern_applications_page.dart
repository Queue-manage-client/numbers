// company_portal/intern/presentation/pages/company_intern_applications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/company_portal/intern/presentation/providers/company_intern_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

class CompanyInternApplicationsPage extends ConsumerWidget {
  final String internshipId;

  const CompanyInternApplicationsPage({
    super.key,
    required this.internshipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(internshipApplicationsProvider(internshipId));
    final internshipAsync = ref.watch(companyInternshipProvider(internshipId));

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: internshipAsync.when(
          data: (intern) => Text(intern?.title ?? '申し込み一覧'),
          loading: () => const Text('申し込み一覧'),
          error: (_, __) => const Text('申し込み一覧'),
        ),
      ),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: ColorPalette.neutral600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '申し込みはまだありません',
                    style: TextStylePalette.subText,
                  ),
                ],
              ),
            );
          }

          // ステータスでグループ化
          final pending = applications.where((a) => a.status == ApplicationStatus.pending).toList();
          final approved = applications.where((a) => a.status == ApplicationStatus.approved).toList();
          final rejected = applications.where((a) => a.status == ApplicationStatus.rejected).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(internshipApplicationsProvider(internshipId));
            },
            color: ColorPalette.primaryColor,
            backgroundColor: ColorPalette.neutral800,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // サマリー
                _buildSummary(pending.length, approved.length, rejected.length),
                const SizedBox(height: 24),

                // 審査中
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader('審査中', pending.length, Colors.orange),
                  ...pending.map((app) => _ApplicationCard(
                    application: app,
                    internshipId: internshipId,
                  )),
                  const SizedBox(height: 16),
                ],

                // 承認済み
                if (approved.isNotEmpty) ...[
                  _buildSectionHeader('承認済み', approved.length, Colors.green),
                  ...approved.map((app) => _ApplicationCard(
                    application: app,
                    internshipId: internshipId,
                  )),
                  const SizedBox(height: 16),
                ],

                // 却下
                if (rejected.isNotEmpty) ...[
                  _buildSectionHeader('却下', rejected.length, Colors.red),
                  ...rejected.map((app) => _ApplicationCard(
                    application: app,
                    internshipId: internshipId,
                  )),
                ],
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました', style: TextStylePalette.normalText),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(internshipApplicationsProvider(internshipId)),
                child: Text('再読み込み', style: TextStyle(color: ColorPalette.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(int pending, int approved, int rejected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('審査中', pending, Colors.orange),
          _buildSummaryItem('承認', approved, Colors.green),
          _buildSummaryItem('却下', rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: FontSizePalette.size24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStylePalette.smTitle,
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  final InternshipApplication application;
  final String internshipId;

  const _ApplicationCard({
    required this.application,
    required this.internshipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(applicationManagementNotifierProvider).isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: ColorPalette.neutral800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        side: BorderSide(color: ColorPalette.neutral600),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorPalette.neutral600,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: ColorPalette.neutral400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.userProfile?.nickname ?? 'ユーザー',
                        style: TextStylePalette.smTitle,
                      ),
                      if (application.userProfile?.university != null)
                        Text(
                          application.userProfile!.university!,
                          style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(application.status),
              ],
            ),

            // メッセージ
            if (application.message != null && application.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.neutral900,
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '応募メッセージ',
                      style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.message!,
                      style: TextStylePalette.normalText,
                    ),
                  ],
                ),
              ),
            ],

            // 職務経歴書
            if (application.userProfile?.resumeUrl != null &&
                application.userProfile!.resumeUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final supabase = Supabase.instance.client;
                  final publicUrl = supabase.storage
                      .from('documents')
                      .getPublicUrl(application.userProfile!.resumeUrl!);
                  final uri = Uri.parse(publicUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.description, size: 16),
                label: Text(
                  application.userProfile!.resumeFileName ?? '職務経歴書を表示',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primaryColor,
                  side: const BorderSide(color: ColorPalette.primaryColor),
                ),
              ),
            ],

            // 申し込み日時
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: ColorPalette.neutral400),
                const SizedBox(width: 4),
                Text(
                  '申込日: ${_formatDateTime(application.appliedAt)}',
                  style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                ),
              ],
            ),

            // アクションボタン
            if (application.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _showRejectDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                      child: const Text('却下'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _approve(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: ColorPalette.neutral0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorPalette.neutral0,
                              ),
                            )
                          : const Text('承認'),
                    ),
                  ),
                ],
              ),
            ],

            // 却下理由
            if (application.status == ApplicationStatus.rejected &&
                application.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '却下理由',
                      style: TextStylePalette.smText.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.rejectionReason!,
                      style: TextStylePalette.normalText,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        text = '審査中';
        break;
      case ApplicationStatus.approved:
        color = Colors.green;
        text = '承認';
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        text = '却下';
        break;
      case ApplicationStatus.cancelled:
        color = ColorPalette.neutral600;
        text = 'キャンセル';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: FontSizePalette.size12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _approve(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(applicationManagementNotifierProvider.notifier);
    final success = await notifier.approve(application.id, internshipId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '承認しました' : '承認に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('申し込みを却下', style: TextStylePalette.smTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'この申し込みを却下しますか？',
              style: TextStylePalette.normalText,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStylePalette.normalText,
              decoration: InputDecoration(
                hintText: '却下理由（任意）',
                hintStyle: TextStylePalette.hintText,
                filled: true,
                fillColor: ColorPalette.neutral900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル', style: TextStyle(color: ColorPalette.neutral400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier = ref.read(applicationManagementNotifierProvider.notifier);
              final success = await notifier.reject(
                application.id,
                internshipId,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '却下しました' : '却下に失敗しました'),
                    backgroundColor: success ? ColorPalette.neutral600 : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('却下する'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
