// feed/presentation/widgets/vertical_video_feed.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';
import '../providers/feed_provider.dart';

class VerticalVideoFeed extends ConsumerStatefulWidget {
  const VerticalVideoFeed({super.key});

  @override
  ConsumerState<VerticalVideoFeed> createState() => _VerticalVideoFeedState();
}

class _VerticalVideoFeedState extends ConsumerState<VerticalVideoFeed> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    // 前のページの動画を一時停止
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    // 新しいページの動画を再生
    _controllers[index]?.play();
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

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          allowImplicitScrolling: true, // 隣接ページを事前にビルド
          itemCount: videos.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _VerticalVideoPage(
              video: video,
              isActive: index == _currentIndex,
              onControllerCreated: (controller) {
                _controllers[index] = controller;
                if (index == _currentIndex) {
                  controller.play();
                }
              },
              onControllerDisposed: () {
                _controllers.remove(index);
              },
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

class _VerticalVideoPage extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;
  final Function(VideoPlayerController) onControllerCreated;
  final VoidCallback onControllerDisposed;

  const _VerticalVideoPage({
    required this.video,
    required this.isActive,
    required this.onControllerCreated,
    required this.onControllerDisposed,
  });

  @override
  State<_VerticalVideoPage> createState() => _VerticalVideoPageState();
}

class _VerticalVideoPageState extends State<_VerticalVideoPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(_VerticalVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    final videoPath = widget.video['video_path'] as String?;
    if (videoPath == null || videoPath.isEmpty) return;

    // Use pre-resolved signed URL if available, otherwise generate one
    String videoUrl;
    final preResolved = widget.video['video_url'] as String?;
    if (preResolved != null && preResolved.isNotEmpty) {
      videoUrl = preResolved;
    } else {
      final supabase = Supabase.instance.client;
      try {
        videoUrl = videoPath.startsWith('http')
            ? videoPath
            : await supabase.storage
                .from('company-videos')
                .createSignedUrl(videoPath, 3600);
      } catch (e) {
        debugPrint('Error creating signed URL: $e');
        return;
      }
    }

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      _controller!.setLooping(true);

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      widget.onControllerCreated(_controller!);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    widget.onControllerDisposed();
    _controller?.dispose();
    super.dispose();
  }

  void _onTapVideo() {
    if (_controller == null) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.video['companies'] as Map<String, dynamic>?;
    final companyName = company?['name'] as String? ?? '不明';
    final companyId = company?['id'] as String? ?? '';
    final title = widget.video['title'] as String? ?? '';
    final tags = (widget.video['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: _onTapVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 動画または読み込み中表示
          Container(
            color: ColorPalette.neutral900,
            child: _isInitialized && _controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Image.asset(
                    'assets/images/tiktok.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),

          // 一時停止中のみアイコン表示
          if (_isInitialized && !_isPlaying)
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
                              color: ColorPalette.neutral400.withValues(alpha: 0.3),
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
