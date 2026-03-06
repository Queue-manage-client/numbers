import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'feed_page.dart';

class FeatureDetailPage extends StatelessWidget {
  final SlideData slide;

  const FeatureDetailPage({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: CustomScrollView(
        slivers: [
          // ヘッダー画像 + タイトル
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: ColorPalette.neutral900,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                slide.title,
                style: const TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size16,
                  fontVariations: [FontVariation('wght', 900)],
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/3.png',
                    fit: BoxFit.cover,
                  ),
                  // グラデーションオーバーレイ
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  // サブタイトル
                  Positioned(
                    bottom: 56,
                    left: SpacePalette.base,
                    right: SpacePalette.base,
                    child: Text(
                      slide.subtitle,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size14,
                        fontVariations: const [FontVariation('wght', 600)],
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 動画数
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacePalette.base,
                SpacePalette.base,
                SpacePalette.base,
                SpacePalette.sm,
              ),
              child: Text(
                '${slide.thumbnails.length}本の動画',
                style: TextStylePalette.subText,
              ),
            ),
          ),

          // 動画グリッド
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SpacePalette.sm,
                mainAxisSpacing: SpacePalette.sm,
                childAspectRatio: 16 / 9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      color: ColorPalette.neutral800,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      slide.thumbnails[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
                childCount: slide.thumbnails.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: SpacePalette.lg),
          ),
        ],
      ),
    );
  }
}
