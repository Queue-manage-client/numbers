import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company/presentation/providers/company_provider.dart';

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

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    controller.initialize().then((_) {
      if (mounted && _currentIndex == index) {
        controller.play();
        controller.setLooping(true);
        setState(() {});
      }
    });

    _videoControllers[index] = controller;
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                '動画がありません',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 動画URLを取得して初期化
          for (int i = 0; i < videos.length; i++) {
            final video = videos[i];
            final videoPath = video['video_path'] as String?;
            if (videoPath != null) {
              final supabase = Supabase.instance.client;
              final videoUrl = supabase.storage.from('videos').getPublicUrl(videoPath);
              _initializeVideo(i, videoUrl);
            }
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

              return GestureDetector(
                onLongPressStart: (_) {
                  setState(() {
                    _showKeywords[index] = true;
                  });
                },
                onLongPressEnd: (_) {
                  setState(() {
                    _showKeywords[index] = false;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 動画プレイヤー
                    if (controller != null && controller.value.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else if (thumbnailUrl != null)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    // オーバーレイ情報
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
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 企業名
                            if (company != null)
                              GestureDetector(
                                onTap: () {
                                  if (companyId != null) {
                                    context.go('/company/$companyId');
                                  }
                                },
                                child: Text(
                                  company['name'] as String? ?? '企業名不明',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // タイトル
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 4),
                            // 説明
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            // キーワード（長押し時）
                            if (showKeywords && tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // 右上のアクションボタン
                    Positioned(
                      top: 40,
                      right: 16,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              context.go('/search/videos');
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              context.go('/my-page');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: Colors.black,
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
    );
  }
}
