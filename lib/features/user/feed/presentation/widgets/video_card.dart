// feed/presentation/widgets/video_card.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';

class VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VideoPlayerController? controller;
  final SupabaseClient supabase;

  const VideoCard({
    super.key,
    required this.video,
    required this.supabase,
    this.controller,
  });

  Widget _buildPlaceholder(String? companyName) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.neutral200,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorPalette.neutral100,
                borderRadius: BorderRadius.circular(RadiusPalette.base),
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: ColorPalette.neutral400,
              ),
            ),
            const SizedBox(height: SpacePalette.base),
            if (companyName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                child: Text(
                  companyName,
                  style: TextStylePalette.title,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: SpacePalette.sm),
            Text(
              '動画を準備中です',
              style: TextStylePalette.subText,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = video['companies'] as Map<String, dynamic>?;
    final description = video['description'] as String? ?? '';
    final thumbnailPath = video['thumbnail_path'] as String?;

    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      try {
        thumbnailUrl = supabase.storage.from('company-thumbnails').getPublicUrl(thumbnailPath);
      } catch (e) {
        // エラー時はthumbnailPathがURLかチェック
        thumbnailUrl = thumbnailPath.startsWith('http') ? thumbnailPath : null;
      }
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // 上部アイコン行
          Padding(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Row(
              children: [
                // プロフィールアイコン
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorPalette.neutral400,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: ColorPalette.neutral500,
                    size: 20,
                  ),
                ),
                const Spacer(),
                // ブックマークアイコン
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorPalette.neutral100,
                    borderRadius: BorderRadius.circular(RadiusPalette.base),
                  ),
                  child: Icon(
                    Icons.bookmark_border,
                    color: ColorPalette.neutral500,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // 動画プレイヤー
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacePalette.base,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RadiusPalette.lg),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: _buildVideoPlayer(
                    controller,
                    thumbnailUrl,
                    company?['name'] as String?,
                  ),
                ),
              ),
            ),
          ),

          // 下部情報
          Padding(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 会社名
                Text(
                  company?['name'] as String? ?? 'Company Name',
                  style: TextStylePalette.title,
                ),
                const SizedBox(height: SpacePalette.sm),
                // 説明文
                Text(
                  description.isNotEmpty
                      ? description
                      : '企業の説明文がここに表示されます',
                  style: TextStylePalette.subText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(
    VideoPlayerController? controller,
    String? thumbnailUrl,
    String? companyName,
  ) {
    // コントローラーが初期化されている場合
    if (controller != null && controller.value.isInitialized) {
      return VideoPlayer(controller);
    }

    // サムネイルがある場合
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(companyName);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(companyName);
        },
      );
    }

    // プレースホルダー表示
    return _buildPlaceholder(companyName);
  }
}