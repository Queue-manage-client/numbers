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

// 特集タブ - バナーカルーセル + Admin設定セクション
class _FeaturedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(feedBannersProvider);
    final sectionsAsync = ref.watch(feedSectionsProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // バナーカルーセル（タブ直下、padding無し、白銀比）
        bannersAsync.when(
          data: (banners) {
            if (banners.isEmpty) return const SizedBox.shrink();
            return _BannerCarousel(banners: banners);
          },
          loading: () {
            final width = MediaQuery.of(context).size.width;
            final height = width / 1.414;
            return SizedBox(
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
            );
          },
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Admin設定の特集セクション
        sectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(SpacePalette.base),
                child: Center(
                  child: Text(
                    '特集コンテンツがありません',
                    style: TextStylePalette.subText,
                  ),
                ),
              );
            }
            return Column(
              children: sections.map((section) {
                final sectionTitle = section['title'] as String? ?? '';
                final videos = section['videos'] as List<Map<String, dynamic>>? ?? [];
                if (videos.isEmpty) return const SizedBox.shrink();
                return _CuratedVideoSection(
                  title: sectionTitle,
                  videos: videos,
                );
              }).toList(),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.all(SpacePalette.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: ColorPalette.primaryColor,
              ),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '読み込みに失敗しました',
                    style: TextStylePalette.subText,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(feedSectionsProvider);
                      ref.invalidate(feedBannersProvider);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                      side: const BorderSide(
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

// バナーカルーセル（自動スクロール、白銀比、padding無し）
class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.banners.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width / 1.414; // 白銀比

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = banner['image_url'] as String? ?? '';
              final linkUrl = banner['link_url'] as String?;

              return GestureDetector(
                onTap: () {
                  if (linkUrl != null && linkUrl.isNotEmpty) {
                    context.push(linkUrl);
                  }
                },
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ColorPalette.neutral800,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: ColorPalette.neutral400,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: ColorPalette.neutral800,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: ColorPalette.neutral400,
                            size: 40,
                          ),
                        ),
                      ),
              );
            },
          ),
          // ページインジケーター
          if (widget.banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (index) {
                  return Container(
                    width: _currentPage == index ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPage == index
                          ? ColorPalette.neutral0
                          : ColorPalette.neutral0.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// Admin設定の特集セクション
class _CuratedVideoSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> videos;

  const _CuratedVideoSection({
    required this.title,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションタイトル
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacePalette.base,
            SpacePalette.lg,
            SpacePalette.base,
            SpacePalette.sm,
          ),
          child: Text(
            title,
            style: TextStylePalette.smHeader,
          ),
        ),

        // 動画横スクロールリスト（16:9サムネ + タイトルオーバーレイ）
        SizedBox(
          height: 140,
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
                child: _SectionVideoCard(video: video),
              );
            },
          ),
        ),
      ],
    );
  }
}

// セクション内の動画カード（16:9、タイトルオーバーレイ）
class _SectionVideoCard extends StatelessWidget {
  final Map<String, dynamic> video;

  const _SectionVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final title = video['title'] as String? ?? '無題';
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;
    final thumbnailUrl = video['thumbnail_url'] as String?;

    // 16:9 aspect ratio
    const double cardWidth = 220;
    const double cardHeight = cardWidth * 9 / 16;

    return GestureDetector(
      onTap: () {
        if (companyId != null && videoId != null) {
          context.push('/companies/$companyId/videos/$videoId');
        }
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // サムネイル画像
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: ColorPalette.neutral600,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 36,
                        color: ColorPalette.neutral400,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: ColorPalette.neutral600,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 36,
                    color: ColorPalette.neutral400,
                  ),
                ),
              ),

            // グラデーション + タイトルオーバーレイ
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(SpacePalette.sm),
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: FontSizePalette.size12,
                    fontVariations: [FontVariation('wght', 700)],
                    color: ColorPalette.neutral0,
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
