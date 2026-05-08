// feed/presentation/pages/feed_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/domain/models/company.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';
import '../widgets/vertical_video_feed.dart';

// ロゴ画像がない企業用のプレースホルダー
Widget _companyPlaceholder(String name) {
  return Container(
    color: ColorPalette.neutral600,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: const TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: 28,
          fontVariations: [FontVariation('wght', 800)],
          color: ColorPalette.neutral400,
        ),
      ),
    ),
  );
}

// 選択中のホームタブインデックス
final selectedHomeTabProvider = StateProvider<int>((ref) => 1);

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  bool _isSyncingFromTab = false;
  final _tabBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(selectedHomeTabProvider);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _pageController = PageController(initialPage: initialIndex);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _isSyncingFromTab = true;
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) => _isSyncingFromTab = false);
      }
      ref.read(selectedHomeTabProvider.notifier).state = _tabController.index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPageTour();
    });
  }

  Future<void> _startPageTour() async {
    await AppTourService.showPageTourIfNeeded(
      context: context,
      pageKey: 'feed',
      targets: [
        AppTourService.createTarget(
          key: _tabBarKey,
          title: 'タブ切り替え',
          description: '「特集」で注目のコンテンツ、「トップ」で動画フィード、「アカウント」でプロフィールや設定にアクセスできます。左右スワイプでも切り替えられます。',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // 認証状態の変更を監視
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.whenData((state) {
        if (state.session == null) {
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

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 6.0, bottom: 6.0),
          child: Image.asset(
            'assets/images/icon.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/search/videos'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // タブバー（特集・トップ・その他）— スワイプ連動
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorPalette.neutral600,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                key: _tabBarKey,
                controller: _tabController,
                indicatorColor: ColorPalette.primaryColor,
                indicatorWeight: 3,
                labelColor: ColorPalette.neutral0,
                unselectedLabelColor: ColorPalette.neutral400,
                labelStyle: const TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size14,
                  fontVariations: [FontVariation('wght', 800)],
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size14,
                  fontVariations: [FontVariation('wght', 600)],
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '特集'),
                  Tab(text: 'トップ'),
                  Tab(text: 'アカウント'),
                ],
              ),
            ),

            // メインコンテンツ — スワイプで切り替え
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (!_isSyncingFromTab) {
                    _tabController.animateTo(index);
                  }
                },
                children: [
                  _FeaturedTab(),
                  const VerticalVideoFeed(),
                  const _OthersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 特集タブ - Adminで作成したセクション + 視聴履歴を表示
class _FeaturedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminSectionsAsync = ref.watch(feedSectionsProvider);
    final supabase = Supabase.instance.client;

    return adminSectionsAsync.when(
      data: (allSections) {
        // watched_history以外のセクション
        final mainSections = allSections
            .where((s) => s.sectionType != 'watched_history')
            .toList();
        // watched_historyセクションがあるか
        final hasWatchedHistory = allSections.any((s) => s.sectionType == 'watched_history');

        // スライドショー(1) + メインセクション + 視聴履歴(1)
        final itemCount = 1 + mainSections.length + (hasWatchedHistory ? 1 : 0);

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // スライドショー
            if (index == 0) {
              return const _ImageSlideshow();
            }

            // Adminで作成したセクション
            if (index <= mainSections.length) {
              final section = mainSections[index - 1];

              // 企業セクション
              if (section.sectionType == 'company') {
                if (section.companies.isEmpty) return const SizedBox.shrink();
                return _CompanySection(
                  title: section.title,
                  companies: section.companies,
                );
              }

              // 動画セクション
              if (section.videos.isEmpty) return const SizedBox.shrink();

              // 1番目のセクションは縦長カードで特別表示
              if (index == 1) {
                return _HighlightVideoSection(
                  title: section.title,
                  videos: section.videos,
                  supabase: supabase,
                );
              }

              return _TopicVideoSection(
                title: section.title,
                videos: section.videos,
                supabase: supabase,
              );
            }

            // 視聴履歴セクション
            return const _WatchedVideosSection();
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: ColorPalette.primaryColor),
      ),
      error: (error, stack) => _buildErrorState(context, ref),
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

// 自動スクロールスライドショー（DB連携：feed_bannersテーブルから取得）
class _ImageSlideshow extends ConsumerStatefulWidget {
  const _ImageSlideshow();

  @override
  ConsumerState<_ImageSlideshow> createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends ConsumerState<_ImageSlideshow> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  static const _defaultGradients = [
    [Color(0xFF1a237e), Color(0xFF0d47a1)],
    [Color(0xFF004d40), Color(0xFF00695c)],
    [Color(0xFF4a148c), Color(0xFF6a1b9a)],
    [Color(0xFFbf360c), Color(0xFFd84315)],
    [Color(0xFF1b5e20), Color(0xFF2e7d32)],
    [Color(0xFF880e4f), Color(0xFFad1457)],
    [Color(0xFF0d47a1), Color(0xFF1565c0)],
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int slideCount) {
    _timer?.cancel();
    if (slideCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % slideCount;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(feedBannersProvider);
    final banners = bannersAsync.valueOrNull ?? [];
    final screenWidth = MediaQuery.of(context).size.width;

    if (banners.isEmpty) {
      return SizedBox(height: screenWidth * 9 / 16);
    }

    // 初回のみタイマー起動
    if (_timer == null || !_timer!.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll(banners.length);
      });
    }

    return Column(
      children: [
        SizedBox(
          height: screenWidth * 9 / 16,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              final title = banner['title'] as String? ?? '';
              final subtitle = banner['subtitle'] as String? ?? '';
              final imageUrl = banner['image_url'] as String?;
              final bannerId = banner['id'] as String? ?? 'banner-$index';
              final gradient = _defaultGradients[index % _defaultGradients.length];

              return GestureDetector(
                onTap: () {
                  context.push('/feature/$bannerId', extra: SlideData(
                    id: bannerId,
                    title: title,
                    subtitle: subtitle,
                  ));
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景: DB画像 or グラデーション
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                        ),
                      ),
                    // 下部グラデーションオーバーレイ
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // テキスト（下部配置）
                    Positioned(
                      bottom: 20,
                      left: SpacePalette.base,
                      right: SpacePalette.base,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size12,
                              fontVariations: const [
                                FontVariation('wght', 600),
                              ],
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: SpacePalette.xs),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size20,
                              fontVariations: [FontVariation('wght', 900)],
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: SpacePalette.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: _currentPage == index
                    ? ColorPalette.primaryColor
                    : ColorPalette.neutral600,
              ),
            ),
          ),
        ),
        const SizedBox(height: SpacePalette.base),
      ],
    );
  }
}

class SlideData {
  final String id;
  final String title;
  final String subtitle;

  const SlideData({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

// 企業セクション（横スクロール、ロゴ + 企業名）
class _CompanySection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> companies;

  const _CompanySection({required this.title, required this.companies});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final cardHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(title, style: TextStylePalette.smHeader),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final companyId = company['id'] as String?;
              final name = company['name'] as String? ?? '';
              final logoUrl = company['logo_url'] as String?;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < companies.length - 1 ? SpacePalette.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (companyId != null) context.push('/companies/$companyId');
                  },
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      color: ColorPalette.neutral800,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? Image.network(logoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _companyPlaceholder(name))
                        : _companyPlaceholder(name),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: SpacePalette.base),
      ],
    );
  }
}

// 1番目のセクション専用 — 縦長カードで表示
class _HighlightVideoSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> videos;
  final SupabaseClient supabase;

  const _HighlightVideoSection({
    required this.title,
    required this.videos,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    const cardWidth = 120.0;
    const cardHeight = cardWidth * 1.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            title,
            style: TextStylePalette.smHeader,
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < videos.length - 1 ? SpacePalette.sm : 0,
                ),
                child: _HighlightVideoCard(
                  video: video,
                  supabase: supabase,
                  cardWidth: cardWidth,
                  rank: index + 1,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: SpacePalette.base),
      ],
    );
  }
}

// 縦長動画カード（ランキング番号 + サムネ + 企業名オーバーレイ）
class _HighlightVideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final SupabaseClient supabase;
  final double cardWidth;
  final int rank;

  const _HighlightVideoCard({
    required this.video,
    required this.supabase,
    required this.cardWidth,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;
    final company = video['companies'] as Map<String, dynamic>?;
    final companyName = company?['name'] as String? ?? '';
    final videoTitle = video['title'] as String? ?? companyName;

    // 縦長サムネイルを優先、なければ通常サムネイル
    final highlightThumb = video['highlight_thumbnail_url'] as String?;
    final normalThumb = video['thumbnail_url'] as String?;
    final thumbnailUrl = (highlightThumb != null && highlightThumb.isNotEmpty)
        ? highlightThumb
        : normalThumb;

    return GestureDetector(
      onTap: () {
        if (companyId != null && videoId != null) {
          context.push('/companies/$companyId/videos/$videoId');
        }
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // サムネイルまたはプレースホルダー
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(videoTitle),
              )
            else
              _buildPlaceholder(videoTitle),

            // ランキング番号（左上）
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(RadiusPalette.base),
                  ),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 32,
                    fontVariations: const [FontVariation('wght', 900)],
                    color: ColorPalette.primaryColor,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // タイトル（下部）
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
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
                child: Text(
                  videoTitle,
                  style: const TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size12,
                    fontVariations: [FontVariation('wght', 700)],
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: ColorPalette.neutral600,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 28,
            fontVariations: [FontVariation('wght', 800)],
            color: ColorPalette.neutral400,
          ),
        ),
      ),
    );
  }
}

// トピック別動画セクション（Huluスタイル）
class _TopicVideoSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> videos;
  final SupabaseClient supabase;

  const _TopicVideoSection({
    required this.title,
    required this.videos,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final thumbnailHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // トピックヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            title,
            style: TextStylePalette.smHeader,
          ),
        ),

        // 動画横スクロールリスト（サムネのみ）
        SizedBox(
          height: thumbnailHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < videos.length - 1 ? SpacePalette.sm : 0,
                ),
                child: _FeaturedVideoCard(
                  video: video,
                  supabase: supabase,
                  cardWidth: cardWidth,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: SpacePalette.base),
      ],
    );
  }
}

// 特集タブの動画カード（サムネのみ）
class _FeaturedVideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final SupabaseClient supabase;
  final double cardWidth;

  const _FeaturedVideoCard({
    required this.video,
    required this.supabase,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;

    // プロバイダーで事前解決済みのthumbnail_urlを優先
    final thumbnailUrl = video['thumbnail_url'] as String?;

    Widget thumbnailWidget = Container(
      color: ColorPalette.neutral600,
      child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          ? Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _placeholder;
              },
              frameBuilder:
                  (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return frame != null ? child : _loadingPlaceholder;
              },
            )
          : _placeholder,
    );

    return GestureDetector(
      onTap: () {
        if (companyId != null && videoId != null) {
          context.push('/companies/$companyId/videos/$videoId');
        }
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: thumbnailWidget,
      ),
    );
  }

  static const Widget _placeholder = Center(
    child: Icon(
      Icons.play_circle_outline,
      size: 40,
      color: ColorPalette.neutral400,
    ),
  );

  static const Widget _loadingPlaceholder = Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: ColorPalette.neutral400,
      ),
    ),
  );
}

// あなたが見た企業セクション（DB連携：video_viewsテーブルから取得）
class _WatchedVideosSection extends ConsumerWidget {
  const _WatchedVideosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);
    final history = historyAsync.valueOrNull ?? [];
    // video_viewsテーブルから視聴済み動画を取得
    final recentVideos = history
        .where((v) => v['company_videos'] != null)
        .map((v) => v['company_videos'] as Map<String, dynamic>)
        .take(5)
        .toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final thumbnailHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            'あなたが見た企業',
            style: TextStylePalette.smHeader,
          ),
        ),

        // 動画横スクロール（サムネ + すべて見るカード）
        SizedBox(
          height: thumbnailHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: recentVideos.length + 1,
            itemBuilder: (context, index) {
              // 6番目: すべて見るカード
              if (index == recentVideos.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: GestureDetector(
                    onTap: () => context.push('/watch-history'),
                    child: Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        color: ColorPalette.neutral800,
                        border: Border.all(
                          color: ColorPalette.neutral600,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: ColorPalette.neutral0,
                              size: 28,
                            ),
                            SizedBox(height: SpacePalette.xs),
                            Text(
                              'すべて見る',
                              style: TextStyle(
                                fontFamily: 'NotoSansJP',
                                fontSize: FontSizePalette.size14,
                                fontVariations: [FontVariation('wght', 600)],
                                color: ColorPalette.neutral0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final video = recentVideos[index];
              final thumbnailPath = video['thumbnail_path'] as String?;
              final title = video['title'] as String? ?? '';
              String? thumbnailUrl;
              if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
                thumbnailUrl = Supabase.instance.client.storage
                    .from('company-thumbnails')
                    .getPublicUrl(thumbnailPath);
              }
              return Padding(
                padding: const EdgeInsets.only(right: SpacePalette.sm),
                child: GestureDetector(
                  onTap: () {
                    final videoId = video['id'] as String?;
                    final companyId = video['company_id'] as String?;
                    if (companyId != null && videoId != null) {
                      context.push('/companies/$companyId/videos/$videoId');
                    }
                  },
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusPalette.base),
                      color: ColorPalette.neutral800,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumbnailUrl != null
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _companyPlaceholder(title),
                          )
                        : _companyPlaceholder(title),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: SpacePalette.sm),
      ],
    );
  }
}

// その他タブ - マイページの内容を移動
class _OthersTab extends ConsumerWidget {
  const _OthersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    final isCompanyUser = roleAsync.valueOrNull == 'company_user';

    if (isCompanyUser) {
      return const _CompanyAccountTab();
    }
    return const _UserAccountTab();
  }
}

// 一般ユーザー用アカウントタブ
class _UserAccountTab extends ConsumerWidget {
  const _UserAccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        return ListView(
          padding: const EdgeInsets.all(SpacePalette.base),
          children: [
            // プロフィール + メニューカード
            Container(
              decoration: BoxDecoration(
                color: ColorPalette.neutral800,
                borderRadius: BorderRadius.circular(RadiusPalette.lg),
                border: Border.all(color: ColorPalette.neutral600),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'プロフィール',
                              style: TextStylePalette.smHeader,
                            ),
                            GestureDetector(
                              onTap: () => context.push('/profile/edit'),
                              child: const Icon(
                                Icons.edit,
                                color: ColorPalette.neutral0,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacePalette.base),
                        _buildInfoRow('メール', user?.email ?? '未設定'),
                        _buildInfoRow('ニックネーム', profile?['nickname'] ?? '未設定'),
                        _buildInfoRow('性別', _getGenderText(profile?['gender'])),
                        _buildInfoRow('学歴', profile?['university'] ?? '未設定'),
                        _buildInfoRow('所在地', profile?['location'] ?? '未設定'),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: ColorPalette.neutral600),
                  ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: ColorPalette.neutral0,
                    ),
                    title: Text(
                      '職務経歴書',
                      style: TextStylePalette.normalText,
                    ),
                    subtitle: Text(
                      profile?['resume_file_name'] as String? ?? '未登録',
                      style: TextStylePalette.smSubText,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ColorPalette.neutral400,
                    ),
                    onTap: () {
                      final resumeUrl = profile?['resume_url'] as String?;
                      if (resumeUrl != null && resumeUrl.isNotEmpty) {
                        context.push('/resume');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('職務経歴書が登録されていません。プロフィール編集から登録してください。')),
                        );
                      }
                    },
                  ),
                  Divider(
                    height: 1,
                    color: ColorPalette.neutral600,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: ColorPalette.neutral0,
                    ),
                    title: Text(
                      '応募履歴',
                      style: TextStylePalette.normalText,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ColorPalette.neutral400,
                    ),
                    onTap: () => context.push('/applications'),
                  ),
                  Divider(
                    height: 1,
                    color: ColorPalette.neutral600,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: ColorPalette.neutral0,
                    ),
                    title: Text(
                      '設定',
                      style: TextStylePalette.normalText,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ColorPalette.neutral400,
                    ),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacePalette.base),

            // ログアウトカード
            _LogoutCard(),
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
    );
  }
}

// 企業ユーザー用アカウントタブ
class _CompanyAccountTab extends ConsumerStatefulWidget {
  const _CompanyAccountTab();

  @override
  ConsumerState<_CompanyAccountTab> createState() => _CompanyAccountTabState();
}

class _CompanyAccountTabState extends ConsumerState<_CompanyAccountTab> {
  final _statsKey = GlobalKey();
  final _profileEditKey = GlobalKey();
  final _videoManageKey = GlobalKey();
  final _jobManageKey = GlobalKey();
  final _internManageKey = GlobalKey();
  final _chatManageKey = GlobalKey();
  final _termsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPageTour();
    });
  }

  Future<void> _startPageTour() async {
    await AppTourService.showPageTourIfNeeded(
      context: context,
      pageKey: 'company_account',
      targets: [
        AppTourService.createTarget(
          key: _statsKey,
          title: '統計情報',
          description: '投稿した動画・求人・インターンの件数を一目で確認できます。',
        ),
        AppTourService.createTarget(
          key: _profileEditKey,
          title: '企業情報編集',
          description: '企業名・説明文・所在地・業界・ウェブサイト・SNSリンク・詳細画像などを編集できます。ここで設定した情報がユーザーに公開されます。',
        ),
        AppTourService.createTarget(
          key: _videoManageKey,
          title: '動画管理',
          description: '企業紹介動画の投稿・編集・削除ができます。動画に求人を紐づけると、ユーザーが動画から直接求人を確認できます。',
        ),
        AppTourService.createTarget(
          key: _jobManageKey,
          title: '求人管理',
          description: '求人情報の作成・編集・公開管理ができます。投稿した求人はマップ上にも表示されます。',
        ),
        AppTourService.createTarget(
          key: _internManageKey,
          title: 'インターン管理',
          description: 'インターンシップ情報の作成・編集・応募者の確認ができます。',
        ),
        AppTourService.createTarget(
          key: _chatManageKey,
          title: 'チャット管理',
          description: 'グループチャットの作成や、応募者とのメッセージのやり取りができます。',
        ),
        AppTourService.createTarget(
          key: _termsKey,
          title: '利用規約・契約条項',
          description: '法人向けの利用規約と契約条項を確認できます。',
          align: ContentAlign.top,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyInfoAsync = ref.watch(companyInfoProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    // データ読み込み中はローディング表示
    if (companyInfoAsync.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ColorPalette.primaryColor),
      );
    }

    // 審査ステータスを確認
    final approvalStatus = companyInfoAsync.whenOrNull(
      data: (info) {
        if (info == null) return null;
        return CompanyApprovalStatus.fromString(info['approval_status'] as String?);
      },
    );
    final isApproved = approvalStatus == CompanyApprovalStatus.approved;

    return ListView(
      padding: const EdgeInsets.all(SpacePalette.base),
      children: [
        // 企業名ヘッダー
        companyInfoAsync.when(
          data: (company) => Text(
            company?['name'] ?? '企業ポータル',
            style: TextStylePalette.header,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => Text('企業ポータル', style: TextStylePalette.header),
        ),
        const SizedBox(height: SpacePalette.lg),

        // 未承認の場合: 審査待ちバナー
        if (!isApproved) ...[
          _ApprovalPendingBanner(
            status: approvalStatus,
            onTap: () => context.go('/company-portal/approval-status'),
          ),
          const SizedBox(height: SpacePalette.lg),
        ],

        // 承認済みの場合のみ: 統計カード + メニュー
        if (isApproved) ...[
          // 統計カード
          statsAsync.when(
            data: (stats) => Row(
              key: _statsKey,
              children: [
                Expanded(
                  child: _CompanyStatCard(
                    icon: Icons.video_library,
                    title: '動画',
                    count: '${stats['videos'] ?? 0}',
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: _CompanyStatCard(
                    icon: Icons.work,
                    title: '求人',
                    count: '${stats['jobs'] ?? 0}',
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: _CompanyStatCard(
                    icon: Icons.school,
                    title: 'インターン',
                    count: '${stats['internships'] ?? 0}',
                  ),
                ),
              ],
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: ColorPalette.primaryColor),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: SpacePalette.lg),

          // 企業メニュー
          Text('メニュー', style: TextStylePalette.smHeader),
          const SizedBox(height: SpacePalette.sm),

          _CompanyMenuTile(
            key: _profileEditKey,
            icon: Icons.business,
            title: '企業情報編集',
            onTap: () => context.go('/company-portal/profile/edit'),
          ),
          _CompanyMenuTile(
            key: _videoManageKey,
            icon: Icons.video_library,
            title: '動画管理',
            onTap: () => context.go('/company-portal/videos'),
          ),
          _CompanyMenuTile(
            key: _jobManageKey,
            icon: Icons.work,
            title: '求人管理',
            onTap: () => context.go('/company-portal/jobs'),
          ),
          _CompanyMenuTile(
            key: _internManageKey,
            icon: Icons.school,
            title: 'インターン管理',
            onTap: () => context.go('/company-portal/interns'),
          ),
          _CompanyMenuTile(
            key: _chatManageKey,
            icon: Icons.chat,
            title: 'チャット管理',
            onTap: () => context.go('/company-portal/chats'),
          ),
          _CompanyMenuTile(
            icon: Icons.credit_card,
            title: 'サブスクリプション',
            onTap: () => context.go('/company-portal/subscription'),
          ),
          _CompanyMenuTile(
            key: _termsKey,
            icon: Icons.description,
            title: '利用規約・契約条項',
            onTap: () => context.go('/company-portal/terms'),
          ),
          const SizedBox(height: SpacePalette.base),
        ],

        // ログアウト
        _LogoutCard(),
      ],
    );
  }
}

// 企業統計カード
class _CompanyStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;

  const _CompanyStatCard({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.sm),
        child: Column(
          children: [
            Icon(icon, size: 24, color: ColorPalette.primaryColor),
            const SizedBox(height: SpacePalette.xs),
            Text(
              count,
              style: TextStylePalette.smHeader.copyWith(
                color: ColorPalette.primaryColor,
              ),
            ),
            const SizedBox(height: SpacePalette.xs),
            Text(
              title,
              style: TextStylePalette.subText.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 企業メニュータイル
class _CompanyMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _CompanyMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorPalette.primaryColor),
        title: Text(title, style: TextStylePalette.normalText),
        trailing: const Icon(Icons.chevron_right, color: ColorPalette.neutral400),
        onTap: onTap,
      ),
    );
  }
}

// 審査待ちバナー
class _ApprovalPendingBanner extends StatelessWidget {
  final CompanyApprovalStatus? status;
  final VoidCallback onTap;

  const _ApprovalPendingBanner({
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRejected = status == CompanyApprovalStatus.rejected;
    final Color bannerColor = isRejected ? Colors.red : Colors.orange;
    final IconData bannerIcon = isRejected ? Icons.cancel_outlined : Icons.hourglass_top;
    final String title = isRejected ? '審査が否認されました' : 'アカウント審査中';
    final String message = isRejected
        ? '詳細を確認するには下のボタンをタップしてください。'
        : '現在、運営による審査を行っています。審査が完了するまで企業ポータルの機能はご利用いただけません。';

    return Container(
      padding: const EdgeInsets.all(SpacePalette.lg),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: bannerColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(bannerIcon, size: 48, color: bannerColor),
          const SizedBox(height: SpacePalette.base),
          Text(
            title,
            style: TextStylePalette.smHeader.copyWith(color: bannerColor),
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            message,
            style: TextStylePalette.normalText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacePalette.base),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.info_outline),
              label: const Text('審査状況を確認'),
              style: OutlinedButton.styleFrom(
                foregroundColor: bannerColor,
                side: BorderSide(color: bannerColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ログアウトカード（共通）
class _LogoutCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final repository = ref.read(authRepositoryProvider);
        await repository.signOut();
        if (context.mounted) {
          context.go('/signup');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(SpacePalette.base),
        decoration: BoxDecoration(
          color: ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.lg),
          border: Border.all(color: ColorPalette.neutral600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: SpacePalette.sm),
            Text(
              'ログアウト',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                color: Colors.red,
                fontSize: FontSizePalette.size14,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStylePalette.subText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStylePalette.normalText,
          ),
        ),
      ],
    ),
  );
}

String _getGenderText(String? gender) {
  switch (gender) {
    case 'male':
      return '男性';
    case 'female':
      return '女性';
    case 'other':
      return 'その他';
    default:
      return '未設定';
  }
}
