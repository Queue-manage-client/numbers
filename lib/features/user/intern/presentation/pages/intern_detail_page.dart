// intern/presentation/pages/intern_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class InternDetailPage extends ConsumerWidget {
  const InternDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 実際にはroute parameterからinternshipIdを取得
    const internshipId = 'dummy-internship-id';
    final internshipAsync = ref.watch(internshipProvider(internshipId));
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: internshipAsync.when(
        data: (internship) {
          if (internship == null) {
            return Center(
              child: Text(
                'インターンが見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          final company = internship['companies'] as Map<String, dynamic>?;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部タイトルエリア
                    Container(
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral900,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(SpacePalette.base),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1日インターン',
                                style: TextStylePalette.header,
                              ),
                              Text(
                                'One Day Intern',
                                style: TextStyle(
                                  fontSize: FontSizePalette.size16,
                                  fontStyle: FontStyle.italic,
                                  color: ColorPalette.neutral400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 検索バー
                    Container(
                      color: ColorPalette.neutral800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                        vertical: SpacePalette.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: TextStylePalette.normalText,
                              decoration: InputDecoration(
                                hintText: '企業名・キーワードで検索',
                                hintStyle: TextStylePalette.hintText,
                                filled: true,
                                fillColor: ColorPalette.neutral900,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: SpacePalette.base,
                                  vertical: SpacePalette.inner,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              '絞り込み',
                              style: TextStyle(
                                color: ColorPalette.neutral0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // インターン画像
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral800,
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(color: ColorPalette.neutral600),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: ColorPalette.neutral600,
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // カテゴリーとエリア
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.inner,
                              vertical: SpacePalette.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral800,
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                              border: Border.all(color: ColorPalette.neutral600),
                            ),
                            child: Text(
                              '建築・土木',
                              style: TextStylePalette.smText,
                            ),
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.inner,
                              vertical: SpacePalette.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral800,
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                              border: Border.all(color: ColorPalette.neutral600),
                            ),
                            child: Text(
                              '関西',
                              style: TextStylePalette.smText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // タイトル
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Text(
                        internship['title'] ?? '建設業界の縁の下の力持ち',
                        style: TextStylePalette.lgListTitle,
                      ),
                    ),

                    const SizedBox(height: SpacePalette.sm),

                    // 企業名
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Text(
                        company?['name'] ?? '大和鉄筋株式会社',
                        style: TextStylePalette.subText,
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // 応募ボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('応募機能は準備中です')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.primaryColor,
                            foregroundColor: ColorPalette.neutral0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'インターン応募',
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
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // 募集内容
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.neutral800,
                          borderRadius: BorderRadius.circular(RadiusPalette.lg),
                          border: Border.all(color: ColorPalette.neutral600),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            iconColor: ColorPalette.neutral0,
                            collapsedIconColor: ColorPalette.neutral0,
                            title: Row(
                              children: [
                                Icon(
                                  Icons.list,
                                  color: ColorPalette.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: SpacePalette.sm),
                                Text(
                                  '募集内容',
                                  style: TextStylePalette.smTitle,
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(SpacePalette.base),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      Icons.check_circle_outline,
                                      '1日インターン｜やりがい学生と繋がりやすい',
                                    ),
                                    const SizedBox(height: SpacePalette.inner),
                                    _buildInfoRow(
                                      Icons.check_circle_outline,
                                      '実際の建設現場で働くプロと直接交流できる説明体験',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.base),

                    // NBS SELECT
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: SpacePalette.lg),
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

                    const SizedBox(height: 80),
                  ],
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
          child: Text(
            'エラー: $error',
            style: TextStylePalette.normalText,
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: ColorPalette.neutral400,
          size: 20,
        ),
        const SizedBox(width: SpacePalette.sm),
        Expanded(
          child: Text(
            text,
            style: TextStylePalette.subText,
          ),
        ),
      ],
    );
  }
}
