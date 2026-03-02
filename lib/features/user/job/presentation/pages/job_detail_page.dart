// job/presentation/pages/job_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final currentRoute = GoRouterState.of(context).uri.path;

    // IDが空の場合はエラー表示
    if (jobId.isEmpty) {
      return Scaffold(
        backgroundColor: ColorPalette.neutral900,
        appBar: AppBar(
          title: const Text('求人詳細'),
        ),
        body: Center(
          child: Text(
            '求人が見つかりません',
            style: TextStylePalette.subText,
          ),
        ),
        bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      );
    }

    final jobAsync = ref.watch(jobProvider(jobId));
    final applicationStatusAsync =
        ref.watch(jobApplicationStatusProvider(jobId));
    final applicationState = ref.watch(jobApplicationNotifierProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/jobs/map');
            }
          },
        ),
        title: Text(
          '求人詳細',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return Center(
              child: Text(
                '求人が見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル
                      Text(
                        job.title,
                        style: TextStylePalette.lgListTitle,
                      ),
                      const SizedBox(height: SpacePalette.sm),

                      // 企業名
                      Text(
                        job.company?.name ?? '企業名未設定',
                        style: TextStylePalette.lgListLeading,
                      ),
                      const SizedBox(height: SpacePalette.lg),

                      // 職種カテゴリ
                      if (job.jobCategory != null)
                        _buildSection('職種カテゴリ', job.jobCategory!),

                      // 給与
                      _buildSection(
                        '給与',
                        job.salaryRangeDisplay.isNotEmpty
                            ? job.salaryRangeDisplay
                            : (job.salary ?? '未設定'),
                      ),

                      // 仕事内容
                      _buildSection('仕事内容', job.description.isNotEmpty ? job.description : '未設定'),

                      // 勤務時間
                      if (job.workingHours != null)
                        _buildSection('勤務時間', job.workingHours!),

                      // 勤務地
                      _buildSection('勤務地', job.location ?? '未設定'),

                      const SizedBox(height: SpacePalette.base),

                      // 応募ボタン（状態に応じて変化）
                      applicationStatusAsync.when(
                        data: (application) => _buildApplicationButton(
                          context,
                          ref,
                          jobId,
                          application,
                          applicationState.isLoading,
                        ),
                        loading: () => _buildLoadingButton(),
                        error: (_, __) => _buildApplicationButton(
                          context,
                          ref,
                          jobId,
                          null,
                          applicationState.isLoading,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'エラー: $error',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStylePalette.smHeader,
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            content,
            style: TextStylePalette.subText,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationButton(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    JobApplication? application,
    bool isLoading,
  ) {
    if (isLoading) {
      return _buildLoadingButton();
    }

    // 申し込み済みの場合
    if (application != null) {
      switch (application.status) {
        case ApplicationStatus.pending:
          return _buildStatusButton(
            context,
            ref,
            '審査中',
            Icons.hourglass_empty,
            ColorPalette.neutral600,
            onPressed: () =>
                _showCancelDialog(context, ref, application.id, jobId),
          );
        case ApplicationStatus.approved:
          return _buildStatusButton(
            context,
            ref,
            '承認済み - チャットで連絡できます',
            Icons.check_circle,
            ColorPalette.primaryColor,
            onPressed: () {
              context.go('/chats');
            },
          );
        case ApplicationStatus.rejected:
          return _buildStatusButton(
            context,
            ref,
            '申し込みが却下されました',
            Icons.cancel,
            Colors.red,
          );
        case ApplicationStatus.cancelled:
          // キャンセル済みの場合は再申し込み可能
          return _buildApplyButton(context, ref, jobId);
      }
    }

    // 未申し込みの場合
    return _buildApplyButton(context, ref, jobId);
  }

  Widget _buildApplyButton(
      BuildContext context, WidgetRef ref, String jobId) {
    return GradientButton(
      text: '求人に応募する',
      onPressed: () => _showApplyDialog(context, ref, jobId),
      icon: const Icon(
        Icons.north_east,
        color: ColorPalette.neutral0,
        size: 20,
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String text,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.neutral800,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            side: BorderSide(color: color),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(text),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.neutral800,
          padding: const EdgeInsets.symmetric(vertical: SpacePalette.base),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
          ),
        ),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorPalette.primaryColor,
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(
      BuildContext context, WidgetRef ref, String jobId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text(
          '求人応募',
          style: TextStylePalette.smTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'この求人に応募しますか？',
              style: TextStylePalette.normalText,
            ),
            const SizedBox(height: SpacePalette.base),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: TextStylePalette.normalText,
              decoration: InputDecoration(
                hintText: 'メッセージ（任意）',
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
            child: Text(
              'キャンセル',
              style: TextStyle(color: ColorPalette.neutral400),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier =
                  ref.read(jobApplicationNotifierProvider.notifier);
              final success = await notifier.apply(
                jobId,
                message: messageController.text.isNotEmpty
                    ? messageController.text
                    : null,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(success ? '応募しました！' : '応募に失敗しました'),
                    backgroundColor:
                        success ? ColorPalette.primaryColor : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
            ),
            child: const Text('応募する'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String applicationId,
    String jobId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text(
          '応募キャンセル',
          style: TextStylePalette.smTitle,
        ),
        content: Text(
          '応募をキャンセルしますか？',
          style: TextStylePalette.normalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '戻る',
              style: TextStyle(color: ColorPalette.neutral400),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final notifier =
                  ref.read(jobApplicationNotifierProvider.notifier);
              final success = await notifier.cancel(applicationId, jobId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'キャンセルしました' : 'キャンセルに失敗しました'),
                    backgroundColor:
                        success ? ColorPalette.neutral600 : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );
  }
}
