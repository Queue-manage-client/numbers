// feed/presentation/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/features/user/profile/presentation/providers/profile_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
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

// 特集タブ - 企業ごとに動画を横並び表示
class _FeaturedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedVideosByCompanyProvider);
    final supabase = Supabase.instance.client;

    return groupedAsync.when(
      data: (grouped) {
        if (grouped.isEmpty) {
          return _buildEmptyState(context);
        }

        final entries = grouped.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: SpacePalette.base),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final parts = entry.key.split('|');
            final companyId = parts[0];
            final companyName = parts.length > 1 ? parts[1] : '不明な企業';
            final videos = entry.value;

            return _CompanyVideoSection(
              companyId: companyId,
              companyName: companyName,
              videos: videos,
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

// 企業ごとの動画セクション
class _CompanyVideoSection extends StatelessWidget {
  final String companyId;
  final String companyName;
  final List<Map<String, dynamic>> videos;
  final SupabaseClient supabase;

  const _CompanyVideoSection({
    required this.companyId,
    required this.companyName,
    required this.videos,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 企業名ヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacePalette.base,
            vertical: SpacePalette.sm,
          ),
          child: GestureDetector(
            onTap: () {
              if (companyId != 'unknown') {
                context.push('/company/$companyId');
              }
            },
            child: Row(
              children: [
                const Icon(
                  Icons.business,
                  color: ColorPalette.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: Text(
                    companyName,
                    style: TextStylePalette.smHeader,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ColorPalette.neutral400,
                ),
              ],
            ),
          ),
        ),

        // 動画横スクロールリスト
        SizedBox(
          height: 200,
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

// 特集タブの動画カード
class _FeaturedVideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final SupabaseClient supabase;

  const _FeaturedVideoCard({
    required this.video,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    final title = video['title'] as String? ?? '無題';
    final thumbnailPath = video['thumbnail_path'] as String?;
    final companyId = video['company_id'] as String?;
    final videoId = video['id'] as String?;

    String? thumbnailUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      thumbnailUrl = supabase.storage
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
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusPalette.mini),
          color: ColorPalette.neutral800,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            Expanded(
              child: Container(
                width: double.infinity,
                color: ColorPalette.neutral600,
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        cacheHeight: 200,
                        cacheWidth: 140,
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

            // タイトル
            Padding(
              padding: const EdgeInsets.all(SpacePalette.sm),
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
          ],
        ),
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
