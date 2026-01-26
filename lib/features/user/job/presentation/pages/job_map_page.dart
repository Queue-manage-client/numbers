// job/presentation/pages/job_map_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class JobMapPage extends StatefulWidget {
  const JobMapPage({super.key});

  @override
  State<JobMapPage> createState() => _JobMapPageState();
}

class _JobMapPageState extends State<JobMapPage> {
  // TODO: データベースから求人情報を取得
  final List<Map<String, dynamic>> _jobs = [
    {
      'id': '1',
      'title': '軽理スタッフ募集｜年間休日120日',
      'company': 'アカウンティング株式会社',
      'salary': '月給23万円～35万円',
      'time': '09:00～18:00',
      'location': '大阪府大阪市北区',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

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
                  fontSize: FontSizePalette.size14,
                  fontStyle: FontStyle.italic,
                  color: ColorPalette.neutral400,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地図エリア（プレースホルダー）
          Container(
            color: ColorPalette.neutral800,
            child: Center(
              child: Icon(
                Icons.map,
                size: 100,
                color: ColorPalette.neutral600,
              ),
            ),
          ),

          // 求人カード
          if (_jobs.isNotEmpty)
            Positioned(
              top: SpacePalette.base,
              left: SpacePalette.base,
              right: SpacePalette.base,
              child: Container(
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
                              _jobs.clear();
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
                            _jobs[0]['title'],
                            style: TextStylePalette.smListTitle,
                          ),
                          const SizedBox(height: SpacePalette.sm),

                          // 企業名
                          Text(
                            _jobs[0]['company'],
                            style: TextStylePalette.subText,
                          ),
                          const SizedBox(height: SpacePalette.inner),

                          // 給与
                          Row(
                            children: [
                              Text(
                                '給与',
                                style: TextStylePalette.smTitle,
                              ),
                              const SizedBox(width: SpacePalette.sm),
                              Text(
                                _jobs[0]['salary'],
                                style: TextStylePalette.normalText,
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacePalette.sm),

                          // 勤務時間
                          Row(
                            children: [
                              Text(
                                '時間',
                                style: TextStylePalette.smTitle,
                              ),
                              const SizedBox(width: SpacePalette.sm),
                              Text(
                                _jobs[0]['time'],
                                style: TextStylePalette.normalText,
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacePalette.sm),

                          // 所在地
                          Text(
                            _jobs[0]['location'],
                            style: TextStylePalette.normalText,
                          ),
                          const SizedBox(height: SpacePalette.base),

                          // 応募ボタン
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/jobs/${_jobs[0]['id']}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPalette.primaryColor,
                                foregroundColor: ColorPalette.neutral0,
                                padding: const EdgeInsets.symmetric(vertical: SpacePalette.inner),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '応募する',
                                    style: TextStyle(
                                      fontSize: FontSizePalette.size16,
                                      fontWeight: FontWeight.w900,
                                      color: ColorPalette.neutral0,
                                    ),
                                  ),
                                  const SizedBox(width: SpacePalette.sm),
                                  const Icon(
                                    Icons.north_east,
                                    color: ColorPalette.neutral0,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
    );
  }
}
