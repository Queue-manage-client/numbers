import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';

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
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 地図エリア（プレースホルダー）
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.map,
                size: 100,
                color: Colors.grey,
              ),
            ),
          ),

          // 上部：タイトルエリア
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '募集を探す',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 求人カード
          if (_jobs.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // カードヘッダー（閉じるボタン）
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 8),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _jobs.clear();
                            });
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // タイトル
                          Text(
                            _jobs[0]['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 企業名
                          Text(
                            _jobs[0]['company'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 給与
                          Row(
                            children: [
                              const Text(
                                '給与',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _jobs[0]['salary'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 勤務時間
                          Row(
                            children: [
                              const Text(
                                '時間',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _jobs[0]['time'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 所在地
                          Text(
                            _jobs[0]['location'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 応募ボタン
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/jobs/${_jobs[0]['id']}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                '応募する',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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

          // 下部：YORODUYA SELECT
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'YORODUYA SELECT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
