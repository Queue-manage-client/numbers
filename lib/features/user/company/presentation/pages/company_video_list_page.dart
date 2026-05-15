// company/presentation/pages/company_video_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';

import 'package:numbers/core/theme/app_theme.dart';

class CompanyVideoListPage extends ConsumerStatefulWidget {
  const CompanyVideoListPage({super.key});

  @override
  ConsumerState<CompanyVideoListPage> createState() => _CompanyVideoListPageState();
}

class _CompanyVideoListPageState extends ConsumerState<CompanyVideoListPage> {
  final Map<String, VideoPlayerController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _initializeVideo(String videoId, String videoUrl) {
    if (_controllers.containsKey(videoId)) {
      return;
    }

    if (videoUrl.isEmpty || !(Uri.tryParse(videoUrl)?.hasAbsolutePath ?? false)) {
      print('無効なビデオURL (videoId: $videoId): $videoUrl');
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controllers[videoId] = controller;

      controller.initialize().then((_) {
        if (!mounted) return;

        if (controller.value.hasError) {
          print('ビデオ初期化エラー (videoId: $videoId): ${controller.value.errorDescription}');
          _controllers[videoId]?.dispose();
          _controllers.remove(videoId);
          if (mounted) {
            setState(() {});
          }
          return;
        }

        if (mounted) {
          setState(() {});
        }
      }).catchError((error, stackTrace) {
        print('ビデオ初期化エラー (videoId: $videoId, URL: $videoUrl): $error');
        print('スタックトレース: $stackTrace');
        if (_controllers.containsKey(videoId)) {
          _controllers[videoId]?.dispose();
          _controllers.remove(videoId);
        }
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print('ビデオコントローラー作成エラー (videoId: $videoId, URL: $videoUrl): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final videosAsync = ref.watch(companyVideosProvider(companyId));
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '企業動画',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Text(
                '動画がありません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoId = video['id'] as String? ?? '';
              final title = video['title'] as String? ?? 'タイトルなし';
              final description = video['description'] as String? ?? '';

              // Use pre-resolved signed URLs from provider
              final videoUrl = video['video_url'] as String?;
              final thumbnailUrl = video['thumbnail_url'] as String?;

              if (videoUrl != null && videoUrl.isNotEmpty) {
                final uri = Uri.tryParse(videoUrl);
                if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                  _initializeVideo(videoId, videoUrl);
                } else {
                  print('無効なビデオURL形式 (videoId: $videoId): $videoUrl');
                }
              }

              final controller = _controllers[videoId];

              return Card(
                margin: const EdgeInsets.only(bottom: SpacePalette.base),
                color: ColorPalette.neutral800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動画プレイヤーまたはサムネイル
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(RadiusPalette.lg),
                        ),
                        child: controller != null && controller.value.isInitialized
                            ? GestureDetector(
                                onTap: () {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                  setState(() {});
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    VideoPlayer(controller),
                                    Center(
                                      child: Icon(
                                        controller.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : thumbnailUrl != null
                                ? Image.network(
                                    thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  )
                                : _buildPlaceholder(),
                      ),
                    ),
                    // タイトルと説明
                    Padding(
                      padding: const EdgeInsets.all(SpacePalette.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStylePalette.smListTitle,
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: SpacePalette.sm),
                            Text(
                              description,
                              style: TextStylePalette.smListLeading,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'エラー: $error',
                style: TextStylePalette.subText,
              ),
              const SizedBox(height: SpacePalette.base),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(companyVideosProvider(companyId));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primaryColor,
                  side: const BorderSide(
                    color: ColorPalette.primaryColor,
                    width: 2,
                  ),
                ),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: ColorPalette.neutral800,
      child: Center(
        child: Icon(
          Icons.video_library,
          color: ColorPalette.neutral400,
          size: 48,
        ),
      ),
    );
  }
}
