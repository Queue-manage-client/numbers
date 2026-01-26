// feed/presentation/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final categoriesAsync = ref.watch(videoCategoriesProvider);
    final videosAsync = ref.watch(filteredVideosProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // 認証状態の変更を監視（ref.listenのみ使用 - 二重監視を回避）
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((state) {
        if (state.session == null || state.session!.user == null) {
          context.go('/login');
        }
      });
    });

    // ユーザーがnullの場合のみローディング表示
    if (user == null) {
      return Scaffold(
        backgroundColor: ColorPalette.neutral900,
        body: Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
      );
    }

    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.go('/search/videos'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: SafeArea(
        child: Column(
          children: [
            // カテゴリタブ
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
              child: categoriesAsync.when(
                data: (categories) {
                  final tabs = ['すべて', ...categories];
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final isSelected = (index == 0 && selectedCategory == null) ||
                          (index > 0 && selectedCategory == tab);
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state =
                              index == 0 ? null : tab;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacePalette.base,
                            vertical: SpacePalette.sm,
                          ),
                          margin: const EdgeInsets.only(right: SpacePalette.sm),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? ColorPalette.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size14,
                              fontVariations: [
                                FontVariation('wght', isSelected ? 800 : 600),
                              ],
                              color: isSelected
                                  ? ColorPalette.neutral0
                                  : ColorPalette.neutral400,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: SpacePalette.base),

            // メインコンテンツ
            Expanded(
              child: videosAsync.when(
                data: (videos) {
                  if (videos.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildVideoGrid(context, videos);
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: ColorPalette.primaryColor,
                  ),
                ),
                error: (error, stack) => _buildErrorState(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(BuildContext context, List<Map<String, dynamic>> videos) {
    final supabase = Supabase.instance.client;

    return RefreshIndicator(
      color: ColorPalette.primaryColor,
      onRefresh: () async {
        // Pull to refresh
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: SpacePalette.sm,
          mainAxisSpacing: SpacePalette.base,
        ),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return RepaintBoundary(
            child: _VideoThumbnailCard(
              video: video,
              supabase: supabase,
              onTap: () {
                // 動画詳細ページへ遷移
                final companyId = video['company_id'] as String?;
                final videoId = video['id'] as String?;
                if (companyId != null && videoId != null) {
                  context.push('/companies/$companyId/videos/$videoId');
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: ColorPalette.neutral400,
            ),
            const SizedBox(height: SpacePalette.lg),
            Text(
              '動画がありません',
              style: TextStylePalette.header,
            ),
            const SizedBox(height: SpacePalette.sm),
            Text(
              '企業が動画を投稿すると、\nここに表示されます',
              textAlign: TextAlign.center,
              style: TextStylePalette.subText,
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/search/videos');
              },
              icon: const Icon(Icons.search),
              label: const Text('動画を検索する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
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
              '動画の読み込みに失敗しました',
              style: TextStylePalette.header,
            ),
            const SizedBox(height: SpacePalette.sm),
            Text(
              'もう一度お試しください',
              style: TextStylePalette.subText,
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(feedVideosProvider);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.primaryColor,
                side: const BorderSide(
                  color: ColorPalette.primaryColor,
                  width: 2,
                ),
                minimumSize: const Size(120, ButtonSizePalette.button),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                ),
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnailCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final SupabaseClient supabase;
  final VoidCallback onTap;

  const _VideoThumbnailCard({
    required this.video,
    required this.supabase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = video['title'] as String? ?? '無題';
    final thumbnailPath = video['thumbnail_path'] as String?;
    final companyName = video['companies']?['name'] as String? ?? '';
    final tags = (video['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    // サムネイルURL取得
    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      thumbnailUrl = supabase.storage
          .from('company-thumbnails')
          .getPublicUrl(thumbnailPath);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral600,
                ),
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        cacheHeight: 300,
                        cacheWidth: 200,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return _placeholder;
                        },
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return frame != null ? child : _loadingPlaceholder;
                        },
                      )
                    : _placeholder,
              ),
            ),

            // 情報部分
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(SpacePalette.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size12,
                        fontVariations: [FontVariation('wght', 800)],
                        color: ColorPalette.neutral0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacePalette.xs),

                    // 企業名
                    if (companyName.isNotEmpty)
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontFamily: 'NotoSansJP',
                          fontSize: FontSizePalette.size12,
                          fontVariations: [FontVariation('wght', 700)],
                          color: ColorPalette.neutral400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // タグ（ネストされたListViewを避けてRowを使用）
                    if (tags.isNotEmpty)
                      Row(
                        children: [
                          for (int i = 0; i < (tags.length > 2 ? 2 : tags.length); i++) ...[
                            if (i > 0) const SizedBox(width: SpacePalette.xs),
                            Flexible(
                              child: Text(
                                '#${tags[i]}',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansJP',
                                  fontSize: 10,
                                  fontVariations: [FontVariation('wght', 600)],
                                  color: ColorPalette.neutral400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // プレースホルダーを定数化してパフォーマンス向上
  static const Widget _placeholder = Center(
    child: Icon(
      Icons.play_circle_outline,
      size: 48,
      color: ColorPalette.neutral400,
    ),
  );

  static const Widget _loadingPlaceholder = Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: ColorPalette.neutral400,
      ),
    ),
  );
}
