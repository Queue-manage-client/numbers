import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'feed_page.dart';

class FeatureDetailPage extends ConsumerWidget {
  final SlideData slide;

  const FeatureDetailPage({super.key, required this.slide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(feedVideosProvider);
    final videos = videosAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: CustomScrollView(
        slivers: [
          // ヘッダー + タイトル
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
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
                      ),
                    ),
                  ),
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
                '${videos.length}本の動画',
                style: TextStylePalette.subText,
              ),
            ),
          ),

          // 動画グリッド（DB連携）
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
                  final video = videos[index];
                  final thumbnailPath = video['thumbnail_path'] as String?;
                  final companyId = video['company_id'] as String?;
                  final videoId = video['id'] as String?;

                  String? thumbnailUrl;
                  if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
                    thumbnailUrl = Supabase.instance.client.storage
                        .from('company-thumbnails')
                        .getPublicUrl(thumbnailPath);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (companyId != null && videoId != null) {
                        context.push('/companies/$companyId/videos/$videoId');
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        color: ColorPalette.neutral800,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.play_circle_outline,
                                    size: 40, color: ColorPalette.neutral400),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.play_circle_outline,
                                  size: 40, color: ColorPalette.neutral400),
                            ),
                    ),
                  );
                },
                childCount: videos.length,
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
