// feed/presentation/pages/feed_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
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
final selectedHomeTabProvider = StateProvider<int>((ref) => 0);

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final selectedTab = ref.watch(selectedHomeTabProvider);

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
            // タブバー（特集・トップ・その他）
            _buildTabBar(context, ref, selectedTab),

            // メインコンテンツ
            Expanded(
              child: _buildTabContent(context, ref, selectedTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, int selectedTab) {
    final tabs = ['特集', 'トップ', 'その他'];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorPalette.neutral600,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedHomeTabProvider.notifier).state = index;
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? ColorPalette.primaryColor
                          : Colors.transparent,
                      width: 3,
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
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, int selectedTab) {
    switch (selectedTab) {
      case 0:
        return _FeaturedTab();
      case 1:
        return const VerticalVideoFeed();
      case 2:
        return const _OthersTab();
      default:
        return _FeaturedTab();
    }
  }
}

// 特集タブ - トピック別に動画を横並び表示
class _FeaturedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(topicSectionsProvider);
    final supabase = Supabase.instance.client;

    return sectionsAsync.when(
      data: (sections) {
        if (sections.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: sections.length + 5, // slideshow + 注目企業 + 急募 + 今週のおすすめ + 若手活躍 + あなたが見た企業 - sections[0]スキップ
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _ImageSlideshow();
            }

            // 注目企業セクション
            if (index == 1) {
              return const _FeaturedCompaniesSection();
            }

            // 急募の企業セクション
            if (index == 2) {
              return const _PopularCompaniesSection();
            }

            // 今週のおすすめ企業セクション
            if (index == 3) {
              return const _RecommendedCompaniesSection();
            }

            // 若手が活躍できる企業セクション
            if (index == 4) {
              return const _YoungActiveCompaniesSection();
            }

            // あなたが見た企業セクション
            if (index == 5) {
              return const _WatchedVideosSection();
            }

            // 残りのセクション
            final sectionIndex = index - 5;
            if (sectionIndex >= sections.length) return const SizedBox.shrink();

            final section = sections[sectionIndex];
            return _TopicVideoSection(
              title: section.title,
              videos: section.videos,
              supabase: supabase,
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: ColorPalette.primaryColor),
      ),
      error: (error, stack) => _buildErrorState(context, ref),
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

// 注目企業セクション（DB連携）
class _FeaturedCompaniesSection extends ConsumerWidget {
  const _FeaturedCompaniesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(feedCompaniesProvider);
    final allCompanies = companiesAsync.valueOrNull ?? [];
    final companies = allCompanies.take(5).toList();
    final cardWidth = 120.0;
    final cardHeight = cardWidth * 1.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            '注目企業',
            style: TextStylePalette.smHeader,
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final name = company['name'] as String? ?? '';
              final companyId = company['id'] as String?;
              final logoUrl = company['logo_url'] as String?;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < companies.length - 1 ? SpacePalette.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (companyId != null) {
                      context.push('/companies/$companyId');
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
                        (logoUrl != null && logoUrl.isNotEmpty)
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _companyPlaceholder(name),
                              )
                            : _companyPlaceholder(name),
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
                              '${index + 1}',
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
                        // 下部に企業名
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
                              name,
                              style: const TextStyle(
                                fontFamily: 'NotoSansJP',
                                fontSize: FontSizePalette.size12,
                                fontVariations: [FontVariation('wght', 700)],
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
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

// 急募の企業セクション（DB連携）
class _PopularCompaniesSection extends ConsumerWidget {
  const _PopularCompaniesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(feedCompaniesProvider);
    final allCompanies = companiesAsync.valueOrNull ?? [];
    // 急募用：後半の企業を表示
    final companies = allCompanies.length > 4 ? allCompanies.sublist(4) : allCompanies;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final thumbnailHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            '急募の企業',
            style: TextStylePalette.smHeader,
          ),
        ),

        SizedBox(
          height: thumbnailHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < companies.length - 1 ? SpacePalette.sm : 0,
                ),
                child: _CompanyThumbnailCard(
                  company: company,
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

// 企業サムネイルカード（共通）
class _CompanyThumbnailCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final double cardWidth;

  const _CompanyThumbnailCard({
    required this.company,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = company['logo_url'] as String?;
    final companyId = company['id'] as String?;
    final name = company['name'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        if (companyId != null) {
          context.push('/companies/$companyId');
        }
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: (logoUrl != null && logoUrl.isNotEmpty)
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _companyPlaceholder(name),
              )
            : _companyPlaceholder(name),
      ),
    );
  }
}

// 今週のおすすめ企業セクション（DB連携）
class _RecommendedCompaniesSection extends ConsumerWidget {
  const _RecommendedCompaniesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(feedCompaniesProvider);
    final allCompanies = companiesAsync.valueOrNull ?? [];
    // おすすめ用：中間の企業を表示
    final start = (allCompanies.length * 0.3).round().clamp(0, allCompanies.length);
    final end = (start + 5).clamp(0, allCompanies.length);
    final companies = allCompanies.sublist(start, end);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final thumbnailHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            '今週のおすすめ企業',
            style: TextStylePalette.smHeader,
          ),
        ),

        SizedBox(
          height: thumbnailHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < companies.length - 1 ? SpacePalette.sm : 0,
                ),
                child: _CompanyThumbnailCard(
                  company: company,
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

// 若手が活躍できる企業セクション（DB連携）
class _YoungActiveCompaniesSection extends ConsumerWidget {
  const _YoungActiveCompaniesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(feedCompaniesProvider);
    final allCompanies = companiesAsync.valueOrNull ?? [];
    // 若手用：最新の企業を表示
    final companies = allCompanies.take(5).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final thumbnailHeight = cardWidth * 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: Text(
            '若手が活躍できる企業',
            style: TextStylePalette.smHeader,
          ),
        ),
        SizedBox(
          height: thumbnailHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < companies.length - 1 ? SpacePalette.sm : 0,
                ),
                child: _CompanyThumbnailCard(
                  company: company,
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
    final thumbnailPath = video['thumbnail_path'] as String?;
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;

    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      thumbnailUrl = supabase.storage
          .from('company-thumbnails')
          .getPublicUrl(thumbnailPath);
    }

    Widget thumbnailWidget = Container(
      color: ColorPalette.neutral600,
      child: thumbnailUrl != null
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
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        return ListView(
          padding: const EdgeInsets.all(SpacePalette.base),
          children: [
            // プロフィールカード
            Container(
              padding: const EdgeInsets.all(SpacePalette.base),
              decoration: BoxDecoration(
                color: ColorPalette.neutral800,
                borderRadius: BorderRadius.circular(RadiusPalette.lg),
                border: Border.all(color: ColorPalette.neutral600),
              ),
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
                  _buildInfoRow('大学', profile?['university'] ?? '未設定'),
                  _buildInfoRow('所在地', profile?['location'] ?? '未設定'),
                ],
              ),
            ),
            const SizedBox(height: SpacePalette.base),

            // メニューカード
            Container(
              decoration: BoxDecoration(
                color: ColorPalette.neutral800,
                borderRadius: BorderRadius.circular(RadiusPalette.lg),
                border: Border.all(color: ColorPalette.neutral600),
              ),
              child: Column(
                children: [
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
            GestureDetector(
              onTap: () async {
                final repository = ref.read(authRepositoryProvider);
                await repository.signOut();
                if (context.mounted) {
                  context.go('/login');
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
    );
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
}
