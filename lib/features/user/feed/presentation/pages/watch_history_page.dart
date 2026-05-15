import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';

class WatchHistoryPage extends ConsumerStatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  ConsumerState<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends ConsumerState<WatchHistoryPage> {
  int _currentPage = 0;
  static const int _videosPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        backgroundColor: ColorPalette.neutral900,
        title: const Text(
          '視聴履歴',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: FontSizePalette.size16,
            fontVariations: [FontVariation('wght', 800)],
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(currentRoute: '/watch-history'),
      body: historyAsync.when(
        data: (allViews) {
          if (allViews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: ColorPalette.neutral400,
                  ),
                  const SizedBox(height: SpacePalette.lg),
                  Text(
                    '視聴履歴はありません',
                    style: TextStylePalette.header,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    '動画を視聴するとここに表示されます',
                    style: TextStylePalette.subText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final totalPages = (allViews.length / _videosPerPage).ceil();
          final start = _currentPage * _videosPerPage;
          final end = (start + _videosPerPage).clamp(0, allViews.length);
          final currentPageViews = allViews.sublist(start, end);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: currentPageViews.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: SpacePalette.sm),
                  itemBuilder: (context, index) {
                    final view = currentPageViews[index];
                    return _buildVideoCard(view);
                  },
                ),
              ),
              if (totalPages > 1) _buildPagination(totalPages),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: ColorPalette.neutral400),
              const SizedBox(height: SpacePalette.lg),
              Text('エラーが発生しました', style: TextStylePalette.header),
              const SizedBox(height: SpacePalette.lg),
              OutlinedButton(
                onPressed: () => ref.invalidate(watchHistoryProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primaryColor,
                  side: const BorderSide(color: ColorPalette.primaryColor, width: 2),
                ),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> view) {
    final video = view['company_videos'] as Map<String, dynamic>?;
    if (video == null) return const SizedBox.shrink();

    final company = video['companies'] as Map<String, dynamic>?;
    final title = video['title'] as String? ?? '';
    final companyName = company?['name'] as String? ?? '';
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;
    final thumbnailPath = video['thumbnail_path'] as String?;
    final watchedAt = view['watched_at'] as String?;

    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      thumbnailUrl = Supabase.instance.client.storage
          .from('company-thumbnails')
          .getPublicUrl(thumbnailPath);
    }

    final watchedLabel = _formatWatchedAt(watchedAt);

    return GestureDetector(
      onTap: () {
        if (companyId != null && videoId != null) {
          context.push('/companies/$companyId/videos/$videoId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 80,
              child: thumbnailUrl != null
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailPlaceholder,
                    )
                  : _thumbnailPlaceholder,
            ),
            const SizedBox(width: SpacePalette.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size14,
                        fontVariations: [FontVariation('wght', 700)],
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size12,
                        fontVariations: const [FontVariation('wght', 500)],
                        color: ColorPalette.neutral400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      watchedLabel,
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size12,
                        fontVariations: const [FontVariation('wght', 400)],
                        color: ColorPalette.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: SpacePalette.sm),
          ],
        ),
      ),
    );
  }

  static final Widget _thumbnailPlaceholder = Container(
    color: ColorPalette.neutral600,
    child: const Center(
      child: Icon(Icons.play_circle_outline, size: 32, color: ColorPalette.neutral400),
    ),
  );

  String _formatWatchedAt(String? watchedAt) {
    if (watchedAt == null) return '';
    try {
      final date = DateTime.parse(watchedAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
      if (diff.inHours < 24) return '${diff.inHours}時間前';
      if (diff.inDays < 7) return '${diff.inDays}日前';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}週間前';
      return '${(diff.inDays / 30).floor()}ヶ月前';
    } catch (_) {
      return '';
    }
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.sm,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.neutral900,
        border: Border(
          top: BorderSide(color: ColorPalette.neutral600, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 0
                  ? ColorPalette.neutral0
                  : ColorPalette.neutral600,
            ),
          ),
          ...List.generate(totalPages, (index) {
            final isSelected = index == _currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = index),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPalette.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  border: isSelected
                      ? null
                      : Border.all(color: ColorPalette.neutral600),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size14,
                    fontVariations: [
                      FontVariation('wght', isSelected ? 700 : 500),
                    ],
                    color: isSelected
                        ? ColorPalette.neutral900
                        : ColorPalette.neutral0,
                  ),
                ),
              ),
            );
          }),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < totalPages - 1
                  ? ColorPalette.neutral0
                  : ColorPalette.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
