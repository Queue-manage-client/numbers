import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  PageController? _pageController;
  int _currentIndex = 0;
  Map<int, VideoPlayerController> _videoControllers = {};
  Map<int, bool> _showKeywords = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _initializeVideo(int index, String videoUrl) {
    if (_videoControllers.containsKey(index)) {
      return;
    }

    // URLの検証
    if (videoUrl.isEmpty || !(Uri.tryParse(videoUrl)?.hasAbsolutePath ?? false)) {
      print('無効なビデオURL (index: $index): $videoUrl');
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;
      
      controller.initialize().then((_) {
        if (!mounted) return;
        
        // 初期化成功後の状態確認
        if (controller.value.hasError) {
          print('ビデオ初期化エラー (index: $index): ${controller.value.errorDescription}');
          _videoControllers[index]?.dispose();
          _videoControllers.remove(index);
          if (mounted) {
            setState(() {});
          }
          return;
        }

        if (_currentIndex == index) {
          controller.play();
          controller.setLooping(true);
        }
        if (mounted) {
          setState(() {});
        }
      }).catchError((error, stackTrace) {
        // ビデオの初期化に失敗した場合（フォーマットエラーなど）
        print('ビデオ初期化エラー (index: $index, URL: $videoUrl): $error');
        print('スタックトレース: $stackTrace');
        // エラーが発生したコントローラーを削除
        if (_videoControllers.containsKey(index)) {
          _videoControllers[index]?.dispose();
          _videoControllers.remove(index);
        }
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print('ビデオコントローラー作成エラー (index: $index, URL: $videoUrl): $e');
    }
  }

  void _onPageChanged(int index) {
    // 前の動画を停止
    if (_videoControllers.containsKey(_currentIndex)) {
      _videoControllers[_currentIndex]!.pause();
    }

    _currentIndex = index;

    // 新しい動画を再生
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
      _videoControllers[index]!.setLooping(true);
    }
  }

  Widget _buildPlaceholder(String? companyName) {
    return Container(
      color: const Color(0xFF1a1a1a),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF323232),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 60,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            if (companyName != null)
              Text(
                companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              '動画を準備中です',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);
    final videosAsync = ref.watch(feedVideosProvider);

    // 認証状態の変更を監視して、未認証の場合はログイン画面へリダイレクト
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.when(
        data: (state) {
          if (!mounted) return;
          if (state.session == null || state.session!.user == null) {
            context.go('/login');
          }
        },
        loading: () {},
        error: (_, __) {
          if (!mounted) return;
          context.go('/login');
        },
      );
    });

    // 認証状態がローディング中またはユーザーがnullの場合はローディング表示
    if (authState.isLoading || user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
    }

    // 認証状態がエラーまたはセッションがない場合はログイン画面へ
    final session = authState.value?.session;
    if (session == null || session.user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
    }

    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: Stack(
        children: [
          // メインコンテンツ
          videosAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  bottomNavigationBar: AppFooter(currentRoute: currentRoute),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '動画がありません',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '企業が動画を投稿すると、\nここに表示されます',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.go('/search/videos');
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('動画を検索する'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF323232),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 動画URLを取得して初期化（video_playerパッケージが利用可能な場合のみ）
              try {
                for (int i = 0; i < videos.length; i++) {
                  final video = videos[i];
                  final videoPath = video['video_path'] as String?;
                  if (videoPath != null && videoPath.isNotEmpty) {
                    try {
                      final supabase = Supabase.instance.client;
                      final videoUrl = supabase.storage.from('videos').getPublicUrl(videoPath);
                      if (videoUrl.isNotEmpty) {
                        // URLの検証を追加
                        final uri = Uri.tryParse(videoUrl);
                        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                          _initializeVideo(i, videoUrl);
                        } else {
                          print('無効なビデオURL形式 (index: $i): $videoUrl');
                        }
                      } else {
                        print('ビデオURLが空です (index: $i, path: $videoPath)');
                      }
                    } catch (e, stackTrace) {
                      // ストレージから取得できない場合はスキップ
                      print('動画URL取得エラー (index: $i, path: $videoPath): $e');
                      print('スタックトレース: $stackTrace');
                    }
                  } else {
                    print('ビデオパスが空です (index: $i)');
                  }
                }
              } catch (e, stackTrace) {
                // video_playerパッケージが利用できない場合はスキップ
                print('動画初期化エラー: $e');
                print('スタックトレース: $stackTrace');
              }

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final company = video['companies'] as Map<String, dynamic>?;
                  final companyId = video['company_id'] as String?;
                  final title = video['title'] as String? ?? '';
                  final description = video['description'] as String? ?? '';
                  final tags = (video['tags'] as List<dynamic>?)?.cast<String>() ?? [];
                  final videoPath = video['video_path'] as String?;
                  final thumbnailPath = video['thumbnail_path'] as String?;

                  String? videoUrl;
                  String? thumbnailUrl;
                  final supabase = Supabase.instance.client;
                  if (videoPath != null) {
                    try {
                      videoUrl = supabase.storage.from('videos').getPublicUrl(videoPath);
                    } catch (e) {
                      // ストレージバケット名が異なる場合はvideo_pathをそのまま使用
                      videoUrl = videoPath.startsWith('http') ? videoPath : null;
                    }
                  }
                  if (thumbnailPath != null) {
                    try {
                      thumbnailUrl = supabase.storage.from('thumbnails').getPublicUrl(thumbnailPath);
                    } catch (e) {
                      // ストレージバケット名が異なる場合はthumbnail_pathをそのまま使用
                      thumbnailUrl = thumbnailPath.startsWith('http') ? thumbnailPath : null;
                    }
                  }

                  final controller = _videoControllers[index];
                  final showKeywords = _showKeywords[index] ?? false;

                  return Container(
                    color: Colors.black,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60, bottom: 20),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // 動画プレイヤーまたはプレースホルダー
                                  AspectRatio(
                                    aspectRatio: 9 / 16,
                                    child: controller != null && controller.value.isInitialized
                                        ? VideoPlayer(controller)
                                        : (thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                            ? Image.network(
                                                thumbnailUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return _buildPlaceholder(company?['name'] as String?);
                                                },
                                              )
                                            : _buildPlaceholder(company?['name'] as String?)),
                                  ),

                                  // 左上プロフィールアイコン
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                                    ),
                                  ),

                                  // 右上ブックマークアイコン
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.bookmark_border, color: Colors.white, size: 24),
                                    ),
                                  ),

                                  // 下部オーバーレイ
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // ユーザー名 + Follow
                                          Row(
                                            children: [
                                              Text(
                                                '@${company?['name']?.toString().toLowerCase().replaceAll(' ', '') ?? 'carmaint1'}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.white, width: 1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Follow',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // 説明文
                                          Text(
                                            description.isNotEmpty
                                                ? description
                                                : '地域に密着した上下水道工事です... #car #tochigi',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => Scaffold(
              backgroundColor: const Color(0xFF000000),
              bottomNavigationBar: AppFooter(currentRoute: currentRoute),
              body: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            error: (error, stack) => Scaffold(
              backgroundColor: Colors.black,
              bottomNavigationBar: AppFooter(currentRoute: currentRoute),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '動画の読み込みに失敗しました',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(feedVideosProvider);
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 上部検索バー
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '職種・地域・キーワード',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    suffixIcon: const Icon(Icons.search, color: Colors.white),
                  ),
                  onTap: () {
                    context.go('/search/videos');
                  },
                  readOnly: true,
                ),
              ),
            ),
          ),

          // 下部の関連ボタンと青い丸ボタン
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 関連を探せる100件
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '関連を探せる100件',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 青い丸ボタン
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A9FE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
