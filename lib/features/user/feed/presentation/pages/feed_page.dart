// feed/presentation/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/features/user/feed/presentation/widgets/video_search_bar.dart';
import 'package:numbers/features/user/feed/presentation/widgets/video_card.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

// Empty State Widget
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

// Error State Widget
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

class FeedPage extends HookConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentIndex = useState(0);
    final videoControllers = useState<Map<int, VideoPlayerController>>({});
    final initializationFailed = useState<Map<int, bool>>({});

    // クリーンアップ
    useEffect(() {
      return () {
        for (var controller in videoControllers.value.values) {
          controller.dispose();
        }
        videoControllers.value.clear();
      };
    }, []);

    final handleInitializationError = useCallback((int index) {
      // エラーが発生したコントローラーを削除
      if (videoControllers.value.containsKey(index)) {
        videoControllers.value[index]?.dispose();
        final newControllers = Map<int, VideoPlayerController>.from(videoControllers.value);
        newControllers.remove(index);
        videoControllers.value = newControllers;
      }
      // 初期化失敗フラグを立てる
      final newFailed = Map<int, bool>.from(initializationFailed.value);
      newFailed[index] = true;
      initializationFailed.value = newFailed;
    }, [videoControllers.value, initializationFailed.value]);

    final initializeVideo = useCallback((int index, String videoUrl) {
      // 既に初期化済み、または初期化に失敗している場合はスキップ
      if (videoControllers.value.containsKey(index) || 
          initializationFailed.value[index] == true) {
        return;
      }

      // URLの検証
      if (videoUrl.isEmpty || !(Uri.tryParse(videoUrl)?.hasAbsolutePath ?? false)) {
        print('無効なビデオURL (index: $index): $videoUrl');
        final newFailed = Map<int, bool>.from(initializationFailed.value);
        newFailed[index] = true;
        initializationFailed.value = newFailed;
        return;
      }

      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        final newControllers = Map<int, VideoPlayerController>.from(videoControllers.value);
        newControllers[index] = controller;
        videoControllers.value = newControllers;
        
        controller.initialize().then((_) {
          // 初期化成功後の状態確認
          if (controller.value.hasError) {
            print('ビデオ初期化エラー (index: $index): ${controller.value.errorDescription}');
            handleInitializationError(index);
            return;
          }

          // 現在のインデックスの動画のみ自動再生
          if (currentIndex.value == index) {
            controller.play();
            controller.setLooping(true);
          }
        }).catchError((error, stackTrace) {
          print('ビデオ初期化エラー (index: $index, URL: $videoUrl): $error');
          print('スタックトレース: $stackTrace');
          handleInitializationError(index);
        });
      } catch (e, stackTrace) {
        print('ビデオコントローラー作成エラー (index: $index, URL: $videoUrl): $e');
        print('スタックトレース: $stackTrace');
        handleInitializationError(index);
      }
    }, [videoControllers.value, initializationFailed.value, currentIndex.value, handleInitializationError]);

    final onPageChanged = useCallback((int index) {
      // 前の動画を停止
      if (videoControllers.value.containsKey(currentIndex.value)) {
        videoControllers.value[currentIndex.value]!.pause();
      }

      currentIndex.value = index;

      // 新しい動画を再生
      if (videoControllers.value.containsKey(index)) {
        videoControllers.value[index]!.play();
        videoControllers.value[index]!.setLooping(true);
      }
    }, [videoControllers.value, currentIndex.value]);

    final initializeVideos = useCallback((List<Map<String, dynamic>> videos) {
      try {
        for (int i = 0; i < videos.length; i++) {
          final video = videos[i];
          final videoPath = video['video_path'] as String?;
          
          if (videoPath != null && videoPath.isNotEmpty) {
            try {
              final supabase = Supabase.instance.client;
              final videoUrl = supabase.storage.from('videos').getPublicUrl(videoPath);
              
              if (videoUrl.isNotEmpty) {
                final uri = Uri.tryParse(videoUrl);
                if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                  initializeVideo(i, videoUrl);
                } else {
                  print('無効なビデオURL形式 (index: $i): $videoUrl');
                  final newFailed = Map<int, bool>.from(initializationFailed.value);
                  newFailed[i] = true;
                  initializationFailed.value = newFailed;
                }
              } else {
                print('ビデオURLが空です (index: $i, path: $videoPath)');
                final newFailed = Map<int, bool>.from(initializationFailed.value);
                newFailed[i] = true;
                initializationFailed.value = newFailed;
              }
            } catch (e) {
              print('動画URL取得エラー (index: $i, path: $videoPath): $e');
              final newFailed = Map<int, bool>.from(initializationFailed.value);
              newFailed[i] = true;
              initializationFailed.value = newFailed;
            }
          } else {
            print('ビデオパスが空です (index: $i)');
            final newFailed = Map<int, bool>.from(initializationFailed.value);
            newFailed[i] = true;
            initializationFailed.value = newFailed;
          }
        }
      } catch (e) {
        print('動画初期化エラー: $e');
      }
    }, [initializeVideo, initializationFailed.value]);

    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);
    final videosAsync = ref.watch(feedVideosProvider);

    // 認証状態の変更を監視
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      next.when(
        data: (state) {
          if (state.session == null || state.session!.user == null) {
            context.go('/login');
          }
        },
        loading: () {},
        error: (_, __) {
          context.go('/login');
        },
      );
    });

    // 認証状態がローディング中
    if (authState.isLoading || user == null) {
      return Scaffold(
        backgroundColor: ColorPalette.neutral100,
        body: Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
      );
    }

    // セッションチェック
    final session = authState.value?.session;
    if (session == null || session.user == null) {
      return Scaffold(
        backgroundColor: ColorPalette.neutral100,
        body: Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
      );
    }

    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ
            videosAsync.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return _buildEmptyState(context);
                }

                // 動画URL取得と初期化
                initializeVideos(videos);

                return PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: onPageChanged,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final controller = videoControllers.value[index];

                    return Padding(
                      padding: const EdgeInsets.all(SpacePalette.base),
                      child: VideoCard(
                        video: video,
                        controller: controller,
                        supabase: Supabase.instance.client,
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
              error: (error, stack) => _buildErrorState(context, ref),
            ),
            
            // 検索バー（上部に配置）
            Positioned(
              top: SpacePalette.base,
              left: 0,
              right: 0,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: SpacePalette.base),
                child: VideoSearchBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}