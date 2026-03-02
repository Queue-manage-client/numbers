// profile/presentation/pages/application_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ApplicationHistoryPage extends ConsumerWidget {
  const ApplicationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(jobApplicationsProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

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
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Text(
                '応募履歴がありません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];

              return Container(
                margin: const EdgeInsets.only(bottom: SpacePalette.base),
                decoration: BoxDecoration(
                  color: ColorPalette.neutral800,
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  border: Border.all(color: ColorPalette.neutral600),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(SpacePalette.base),
                  title: Text(
                    application.job?.title ?? '求人名未設定',
                    style: TextStylePalette.smListTitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacePalette.xs),
                      Text(
                        application.job?.company?.name ?? '企業名未設定',
                        style: TextStylePalette.subText,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      _buildStatusChip(application.status),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ColorPalette.neutral400,
                  ),
                  onTap: () => context.push('/jobs/${application.jobId}'),
                ),
              );
            },
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
