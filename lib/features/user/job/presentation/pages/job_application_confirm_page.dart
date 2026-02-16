// job/presentation/pages/job_application_confirm_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobApplicationConfirmPage extends ConsumerStatefulWidget {
  const JobApplicationConfirmPage({super.key});

  @override
  ConsumerState<JobApplicationConfirmPage> createState() =>
      _JobApplicationConfirmPageState();
}

class _JobApplicationConfirmPageState
    extends ConsumerState<JobApplicationConfirmPage> {
  bool _isApplying = false;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _apply(String jobId) async {
    setState(() => _isApplying = true);

    try {
      final notifier = ref.read(jobApplicationNotifierProvider.notifier);
      final success = await notifier.apply(
        jobId,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
      );

      if (mounted) {
        if (success) {
          context.go('/jobs/$jobId/apply/complete');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('応募に失敗しました', style: TextStylePalette.normalText.copyWith(color: ColorPalette.neutral0)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('応募確認'),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return Center(
              child: Text('求人が見つかりません', style: TextStylePalette.subText),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(SpacePalette.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '以下の求人に応募しますか？',
                  style: TextStylePalette.smTitle,
                ),
                const SizedBox(height: SpacePalette.lg),
                Container(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral800,
                    borderRadius: BorderRadius.circular(RadiusPalette.lg),
                    border: Border.all(color: ColorPalette.neutral600),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: TextStylePalette.smListTitle),
                      const SizedBox(height: SpacePalette.sm),
                      Text('企業名: ${job.company?.name ?? "未設定"}', style: TextStylePalette.subText),
                      if (job.salaryRangeDisplay.isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.sm),
                        Text('給与: ${job.salaryRangeDisplay}', style: TextStylePalette.subText),
                      ],
                      if (job.location != null) ...[
                        const SizedBox(height: SpacePalette.sm),
                        Text('勤務地: ${job.location}', style: TextStylePalette.subText),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SpacePalette.lg),
                Text('メッセージ（任意）', style: TextStylePalette.smTitle),
                const SizedBox(height: SpacePalette.sm),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  style: TextStylePalette.normalText,
                  decoration: InputDecoration(
                    hintText: '自己PRや質問など',
                    hintStyle: TextStylePalette.hintText,
                    filled: true,
                    fillColor: ColorPalette.neutral800,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      borderSide: BorderSide(color: ColorPalette.neutral600),
                    ),
                  ),
                ),
                const SizedBox(height: SpacePalette.sm),
                Text(
                  '応募後、企業が承認するとチャットでやり取りできるようになります。',
                  style: TextStylePalette.smText.copyWith(color: ColorPalette.neutral400),
                ),
                const Spacer(),
                GradientButton(
                  text: '応募する',
                  onPressed: _isApplying ? null : () => _apply(jobId),
                  icon: _isApplying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorPalette.neutral0,
                          ),
                        )
                      : const Icon(Icons.north_east, color: ColorPalette.neutral0, size: 20),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: ColorPalette.primaryColor)),
        error: (error, _) => Center(child: Text('エラー: $error', style: TextStylePalette.subText)),
      ),
    );
  }
}
