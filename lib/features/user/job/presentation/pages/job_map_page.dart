// job/presentation/pages/job_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMapPage extends ConsumerStatefulWidget {
  const JobMapPage({super.key});

  @override
  ConsumerState<JobMapPage> createState() => _JobMapPageState();
}

class _JobMapPageState extends ConsumerState<JobMapPage> {
  Map<String, dynamic>? _selectedJob;

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('募集を探す'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: SpacePalette.base),
            child: Center(
              child: Text(
                'Apply Now',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size20,
                  fontStyle: FontStyle.italic,
                  fontVariations: const [FontVariation('wght', 900)],
                  color: ColorPalette.neutral400,
                ),
              ),
            ),
          ),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          // 最初の求人を自動選択（未選択の場合）
          if (_selectedJob == null && jobs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedJob = jobs.first;
                });
              }
            });
          }

          return Stack(
            children: [
              // 地図エリア（プレースホルダー）
              Container(
                color: ColorPalette.neutral800,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 100,
                        color: ColorPalette.neutral600,
                      ),
                      const SizedBox(height: SpacePalette.base),
                      Text(
                        '${jobs.length}件の求人',
                        style: TextStylePalette.subText,
                      ),
                    ],
                  ),
                ),
              ),

              // 求人カード
              if (_selectedJob != null)
                Positioned(
                  top: SpacePalette.base,
                  left: SpacePalette.base,
                  right: SpacePalette.base,
                  child: _buildJobCard(_selectedJob!),
                ),

              // 下部：NBS SELECT
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Center(
                    child: Text(
                      'NBS SELECT',
                      style: TextStyle(
                        fontSize: FontSizePalette.size12,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.neutral400,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: ColorPalette.primaryColor,
              ),
              const SizedBox(height: SpacePalette.lg),
              Text(
                'エラーが発生しました',
                style: TextStylePalette.header,
              ),
              const SizedBox(height: SpacePalette.sm),
              Text(
                '$error',
                style: TextStylePalette.subText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacePalette.lg),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(jobsProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobId = job['id'] as String? ?? '';
    final title = job['title'] as String? ?? 'タイトルなし';
    final company = job['companies'] as Map<String, dynamic>?;
    final companyName = company?['name'] as String? ?? '企業名不明';
    final salary = job['salary'] as String? ?? '給与未設定';
    final description = job['description'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カードヘッダー（閉じるボタン）
          Padding(
            padding: const EdgeInsets.only(right: SpacePalette.sm, top: SpacePalette.sm),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: ColorPalette.neutral400,
                ),
                onPressed: () {
                  setState(() {
                    _selectedJob = null;
                  });
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacePalette.base,
              0,
              SpacePalette.base,
              SpacePalette.base,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size18,
                    fontVariations: const [FontVariation('wght', 800)],
                    color: ColorPalette.neutral0,
                  ),
                ),
                const SizedBox(height: SpacePalette.sm),

                // 企業名
                Text(
                  companyName,
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size14,
                    fontVariations: const [FontVariation('wght', 500)],
                    color: ColorPalette.neutral400,
                  ),
                ),
                const SizedBox(height: SpacePalette.base),

                // 給与
                Row(
                  children: [
                    Text(
                      '給与',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size14,
                        fontVariations: const [FontVariation('wght', 700)],
                        color: ColorPalette.neutral0,
                      ),
                    ),
                    const SizedBox(width: SpacePalette.sm),
                    Expanded(
                      child: Text(
                        salary,
                        style: TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: FontSizePalette.size14,
                          fontVariations: const [FontVariation('wght', 500)],
                          color: ColorPalette.neutral200,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacePalette.sm),

                // 説明
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size14,
                      fontVariations: const [FontVariation('wght', 400)],
                      color: ColorPalette.neutral400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                ],

                // 詳細リンク
                GestureDetector(
                  onTap: () {
                    context.push('/jobs/$jobId');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '詳細を見る',
                        style: TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: FontSizePalette.size12,
                          fontVariations: const [FontVariation('wght', 600)],
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(width: SpacePalette.xs),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: ColorPalette.primaryColor,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
