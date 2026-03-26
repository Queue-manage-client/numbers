// profile/presentation/pages/application_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ApplicationDetailPage extends ConsumerWidget {
  final String applicationId;

  const ApplicationDetailPage({
    super.key,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final applicationsAsync = ref.watch(jobApplicationsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/applications');
            }
          },
        ),
        title: Text(
          '応募詳細',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: applicationsAsync.when(
        data: (applications) {
          final application = applications
              .where((a) => a.id == applicationId)
              .toList();

          if (application.isEmpty) {
            return Center(
              child: Text(
                '応募情報が見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          final app = application.first;
          final job = app.job;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ステータスバッジ
                _buildStatusBadge(app.status),
                const SizedBox(height: SpacePalette.lg),

                // 求人情報カード
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SpacePalette.base),
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral800,
                    borderRadius: BorderRadius.circular(RadiusPalette.lg),
                    border: Border.all(color: ColorPalette.neutral600),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '求人情報',
                        style: TextStylePalette.smTitle,
                      ),
                      const SizedBox(height: SpacePalette.inner),
                      Text(
                        job?.title ?? '求人タイトル不明',
                        style: TextStylePalette.lgListTitle,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      if (job?.company != null) ...[
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: ColorPalette.neutral400),
                            const SizedBox(width: SpacePalette.xs),
                            Text(
                              job!.company!.name,
                              style: TextStylePalette.subText,
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacePalette.xs),
                      ],
                      if (job?.salaryRangeDisplay != null) ...[
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 16, color: ColorPalette.neutral400),
                            const SizedBox(width: SpacePalette.xs),
                            Text(
                              job!.salaryRangeDisplay,
                              style: TextStylePalette.subText,
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacePalette.xs),
                      ],
                      if (job?.location != null) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: ColorPalette.neutral400),
                            const SizedBox(width: SpacePalette.xs),
                            Expanded(
                              child: Text(
                                job!.location!,
                                style: TextStylePalette.subText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SpacePalette.base),

                // 応募情報カード
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SpacePalette.base),
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral800,
                    borderRadius: BorderRadius.circular(RadiusPalette.lg),
                    border: Border.all(color: ColorPalette.neutral600),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '応募情報',
                        style: TextStylePalette.smTitle,
                      ),
                      const SizedBox(height: SpacePalette.inner),
                      _buildInfoRow(
                        '応募日',
                        _formatDate(app.appliedAt),
                      ),
                      if (app.reviewedAt != null) ...[
                        const SizedBox(height: SpacePalette.sm),
                        _buildInfoRow(
                          '審査日',
                          _formatDate(app.reviewedAt!),
                        ),
                      ],
                      if (app.message != null && app.message!.isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.sm),
                        _buildInfoRow(
                          'メッセージ',
                          app.message!,
                        ),
                      ],
                      if (app.rejectionReason != null && app.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.sm),
                        _buildInfoRow(
                          '却下理由',
                          app.rejectionReason!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SpacePalette.lg),

                // アクションボタン
                if (app.status == ApplicationStatus.approved)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: 'チャットで連絡する',
                      onPressed: () => context.go('/chats'),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: ColorPalette.neutral0,
                        size: 18,
                      ),
                    ),
                  ),

                if (app.status == ApplicationStatus.pending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/applications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.neutral800,
                        foregroundColor: ColorPalette.neutral0,
                        padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(RadiusPalette.base),
                          side: const BorderSide(color: ColorPalette.neutral600),
                        ),
                      ),
                      child: const Text('審査結果をお待ちください'),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: ColorPalette.neutral400),
              const SizedBox(height: SpacePalette.base),
              Text(
                '読み込みに失敗しました',
                style: TextStylePalette.subText,
              ),
              const SizedBox(height: SpacePalette.base),
              ElevatedButton(
                onPressed: () => ref.invalidate(jobApplicationsProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case ApplicationStatus.pending:
        bgColor = Colors.orange.withAlpha(30);
        textColor = Colors.orange;
        text = '審査中';
        icon = Icons.hourglass_empty;
      case ApplicationStatus.approved:
        bgColor = Colors.green.withAlpha(30);
        textColor = Colors.green;
        text = '承認済み';
        icon = Icons.check_circle;
      case ApplicationStatus.rejected:
        bgColor = Colors.red.withAlpha(30);
        textColor = Colors.red;
        text = '却下';
        icon = Icons.cancel;
      case ApplicationStatus.cancelled:
        bgColor = ColorPalette.neutral800;
        textColor = ColorPalette.neutral400;
        text = 'キャンセル';
        icon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.inner,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: SpacePalette.sm),
          Text(
            text,
            style: TextStylePalette.smTitle.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStylePalette.smSubText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStylePalette.normalText,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
