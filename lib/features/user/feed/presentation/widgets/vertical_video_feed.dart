// feed/presentation/widgets/vertical_video_feed.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';
import '../../data/repositories/feed_repository.dart';
import '../providers/feed_provider.dart';

class VerticalVideoFeed extends ConsumerStatefulWidget {
  const VerticalVideoFeed({super.key});

  @override
  ConsumerState<VerticalVideoFeed> createState() => _VerticalVideoFeedState();
}

class _VerticalVideoFeedState extends ConsumerState<VerticalVideoFeed>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _initializing = {};
  List<Map<String, dynamic>> _videos = [];
  bool _initialPreloadDone = false;

  /// プリロード範囲: 現在のページ ± 1
  static const int _preloadRange = 1;

  /// メモリ保持範囲: 現在のページ ± 2（それ以外は破棄）
  static const int _cacheRange = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controllers[_currentIndex]?.pause();
    } else if (state == AppLifecycleState.resumed) {
      final controller = _controllers[_currentIndex];
      if (controller != null && controller.value.isInitialized) {
        controller.play();
      }
    }
  }

  void _onPageChanged(int index) {
    // 前のページを一時停止
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    // 新しいページを再生
    final controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
    }

    // 視聴履歴を記録
    _recordView(index);

    // 隣接動画をプリロード & 遠いコントローラーを破棄
    _preloadAdjacentVideos(index);
    _disposeDistantControllers(index);
  }

  /// 視聴履歴を記録
  void _recordView(int index) {
    if (index < 0 || index >= _videos.length) return;
    final video = _videos[index];
    final videoId = video['id'] as String?;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (videoId != null && userId != null) {
      final repo = FeedRepository(Supabase.instance.client);
      repo.recordView(videoId, userId);
    }
  }

  /// 現在のページ ± _preloadRange のコントローラーを事前初期化
  void _preloadAdjacentVideos(int centerIndex) {
    for (int offset = -_preloadRange; offset <= _preloadRange; offset++) {
      final i = centerIndex + offset;
      if (i >= 0 &&
          i < _videos.length &&
          !_controllers.containsKey(i) &&
          !_initializing.contains(i)) {
        _initializeController(i);
      }
    }
  }

  /// _cacheRange 外のコントローラーを破棄してメモリ解放
  void _disposeDistantControllers(int centerIndex) {
    final toRemove = _controllers.keys
        .where((i) => (i - centerIndex).abs() > _cacheRange)
        .toList();
    for (final key in toRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  /// 指定インデックスの動画コントローラーを初期化
  Future<void> _initializeController(int index) async {
    if (_initializing.contains(index)) return;
    _initializing.add(index);

    final video = _videos[index];
    final videoUrl = video['video_url'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) {
      _initializing.remove(index);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        _initializing.remove(index);
        return;
      }

      _controllers[index] = controller;
      _initializing.remove(index);

      // 現在のページなら自動再生
      if (index == _currentIndex) {
        controller.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      _initializing.remove(index);
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(feedVideosProvider);

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return Center(
            child: Text(
              '動画がありません',
              style: TextStylePalette.normalText,
            ),
          );
        }

        _videos = videos;

        // 初回のみプリロードをトリガー
        if (!_initialPreloadDone) {
          _initialPreloadDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _preloadAdjacentVideos(_currentIndex);
          });
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          allowImplicitScrolling: true,
          itemCount: videos.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _VerticalVideoPage(
              video: video,
              controller: _controllers[index],
              isActive: index == _currentIndex,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: ColorPalette.primaryColor),
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

// =============================================================================
// 個別動画ページ（コントローラーは親から受け取る）
// =============================================================================

class _VerticalVideoPage extends StatefulWidget {
  final Map<String, dynamic> video;
  final VideoPlayerController? controller;
  final bool isActive;

  const _VerticalVideoPage({
    required this.video,
    required this.controller,
    required this.isActive,
  });

  @override
  State<_VerticalVideoPage> createState() => _VerticalVideoPageState();
}

class _VerticalVideoPageState extends State<_VerticalVideoPage> {
  bool _isPlaying = false;
  bool _isBuffering = false;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _attachListener(widget.controller);
  }

  @override
  void didUpdateWidget(_VerticalVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // コントローラーが変わったらリスナーを再接続
    if (widget.controller != oldWidget.controller) {
      _detachListener(oldWidget.controller);
      _attachListener(widget.controller);
    }
  }

  /// 再生状態・バッファリング状態の変化のみ検知するリスナーを接続
  void _attachListener(VideoPlayerController? controller) {
    if (controller == null) return;
    _isPlaying = controller.value.isPlaying;
    _isBuffering = controller.value.isBuffering;
    _listener = () {
      if (!mounted) return;
      final playing = controller.value.isPlaying;
      final buffering = controller.value.isBuffering;
      // 状態が実際に変わった時だけsetState（毎フレーム再描画を防止）
      if (playing != _isPlaying || buffering != _isBuffering) {
        setState(() {
          _isPlaying = playing;
          _isBuffering = buffering;
        });
      }
    };
    controller.addListener(_listener!);
  }

  void _detachListener(VideoPlayerController? controller) {
    if (_listener != null && controller != null) {
      controller.removeListener(_listener!);
    }
    _listener = null;
  }

  @override
  void dispose() {
    _detachListener(widget.controller);
    super.dispose();
  }

  void _onTapVideo() {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isInitialized = controller != null && controller.value.isInitialized;
    final thumbnailUrl = widget.video['thumbnail_url'] as String?;

    final company = widget.video['companies'] as Map<String, dynamic>?;
    final companyName = company?['name'] as String? ?? '不明';
    final companyId = company?['id'] as String? ?? '';
    final title = widget.video['title'] as String? ?? '';
    final tags =
        (widget.video['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: _onTapVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 動画 or サムネイル/プレースホルダー
          Container(
            color: ColorPalette.neutral900,
            child: isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  )
                : _buildPlaceholder(thumbnailUrl),
          ),

          // バッファリング中インジケーター（再生中にバッファが追いつかない場合）
          if (isInitialized && _isBuffering)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral900.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // 一時停止中のみアイコン表示
          if (isInitialized && !_isPlaying && !_isBuffering)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral900.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: ColorPalette.neutral0,
                  size: 40,
                ),
              ),
            ),

          // 動画情報オーバーレイ（下部）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(SpacePalette.base),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ColorPalette.neutral900.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 企業名
                    GestureDetector(
                      onTap: () {
                        if (companyId.isNotEmpty) {
                          context.push('/company/$companyId');
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            color: ColorPalette.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: SpacePalette.xs),
                          Text(
                            companyName,
                            style: TextStylePalette.normalText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SpacePalette.sm),

                    // タイトル
                    Text(
                      title,
                      style: TextStylePalette.smHeader.copyWith(
                        color: ColorPalette.neutral0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacePalette.sm),

                    // タグ
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: SpacePalette.xs,
                        runSpacing: SpacePalette.xs,
                        children: tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.sm,
                              vertical: SpacePalette.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral400
                                  .withValues(alpha: 0.3),
                              borderRadius:
                                  BorderRadius.circular(RadiusPalette.mini),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStylePalette.subText.copyWith(
                                color: ColorPalette.neutral100,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 右側アクションボタン
          Positioned(
            right: SpacePalette.base,
            bottom: 120,
            child: Column(
              children: [
                _ActionButton(
                  icon: Icons.business,
                  label: '企業',
                  onTap: () {
                    if (companyId.isNotEmpty) {
                      context.push('/company/$companyId');
                    }
                  },
                ),
                const SizedBox(height: SpacePalette.base),
                _ActionButton(
                  icon: Icons.info_outline,
                  label: '詳細',
                  onTap: () {
                    final videoId = widget.video['id'] as String?;
                    if (videoId != null && companyId.isNotEmpty) {
                      context.push('/companies/$companyId/videos/$videoId');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 動画読み込み中のプレースホルダー（サムネイル優先表示）
  Widget _buildPlaceholder(String? thumbnailUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // サムネイルがあれば表示、なければデフォルト画像
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/tiktok.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        else
          Image.asset(
            'assets/images/tiktok.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        // ローディングインジケーター
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorPalette.neutral900.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorPalette.neutral900.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: ColorPalette.neutral0,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStylePalette.subText.copyWith(
              color: ColorPalette.neutral0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
