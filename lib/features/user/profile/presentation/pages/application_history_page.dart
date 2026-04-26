// profile/presentation/pages/application_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ApplicationHistoryPage extends ConsumerWidget {
  const ApplicationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAppsAsync = ref.watch(jobApplicationsProvider);
    final internAppsAsync = ref.watch(userApplicationsProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    final isLoading = jobAppsAsync.isLoading || internAppsAsync.isLoading;
    final jobError = jobAppsAsync.error;
    final internError = internAppsAsync.error;
    final error = jobError ?? internError;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/my-page');
            }
          },
        ),
        title: Text(
          '応募履歴',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ColorPalette.primaryColor,
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (jobError != null)
                          Text(
                            '求人データエラー: $jobError',
                            style: TextStylePalette.normalText,
                            textAlign: TextAlign.center,
                          ),
                        if (internError != null)
                          Text(
                            'インターンデータエラー: $internError',
                            style: TextStylePalette.normalText,
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: SpacePalette.base),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(jobApplicationsProvider);
                            ref.invalidate(userApplicationsProvider);
                          },
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildList(context, jobAppsAsync, internAppsAsync),
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncValue jobAppsAsync,
    AsyncValue internAppsAsync,
  ) {
    // 統合リストを作成（応募日時の降順）
    final List<_ApplicationItem> items = [];

    final jobApps = jobAppsAsync.valueOrNull ?? [];
    for (final app in jobApps) {
      items.add(_ApplicationItem(
        title: app.job?.title ?? '求人名未設定',
        companyName: app.job?.company?.name ?? '企業名未設定',
        status: app.status,
        appliedAt: app.appliedAt,
        type: '求人',
        onTap: () => context.push('/jobs/${app.jobId}'),
      ));
    }

    final internApps = internAppsAsync.valueOrNull ?? [];
    for (final app in internApps) {
      items.add(_ApplicationItem(
        title: app.internship?.title ?? 'インターン名未設定',
        companyName: app.internship?.company?.name ?? '企業名未設定',
        status: app.status,
        appliedAt: app.appliedAt,
        type: 'インターン',
        onTap: () => context.push('/interns/${app.internshipId}'),
      ));
    }

    // 応募日時の降順でソート
    items.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

    if (items.isEmpty) {
      return Center(
        child: Text(
          '応募履歴がありません',
          style: TextStylePalette.subText,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SpacePalette.base),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          margin: const EdgeInsets.only(bottom: SpacePalette.base),
          decoration: BoxDecoration(
            color: ColorPalette.neutral800,
            borderRadius: BorderRadius.circular(RadiusPalette.lg),
            border: Border.all(color: ColorPalette.neutral600),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(SpacePalette.base),
            title: Row(
              children: [
                _buildTypeChip(item.type),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStylePalette.smListTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: SpacePalette.xs),
                Text(
                  item.companyName,
                  style: TextStylePalette.subText,
                ),
                const SizedBox(height: SpacePalette.sm),
                _buildStatusChip(item.status),
              ],
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: ColorPalette.neutral400,
            ),
            onTap: item.onTap,
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String type) {
    final isIntern = type == 'インターン';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isIntern
            ? Colors.orange.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: isIntern ? Colors.orange : Colors.blue,
          fontSize: FontSizePalette.size12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        text = '審査中';
        break;
      case ApplicationStatus.approved:
        color = ColorPalette.primaryColor;
        text = '承認済み';
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        text = '却下';
        break;
      case ApplicationStatus.cancelled:
        color = ColorPalette.neutral400;
        text = 'キャンセル';
        break;
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
        text,
        style: TextStyle(
          color: color,
          fontSize: FontSizePalette.size12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ApplicationItem {
  final String title;
  final String companyName;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String type;
  final VoidCallback onTap;

  const _ApplicationItem({
    required this.title,
    required this.companyName,
    required this.status,
    required this.appliedAt,
    required this.type,
    required this.onTap,
  });
}
