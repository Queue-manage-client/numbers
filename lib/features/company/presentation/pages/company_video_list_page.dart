import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/company/presentation/providers/company_provider.dart';

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

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _controllers[videoId] = controller;
  }

  @override
  Widget build(BuildContext context) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final videosAsync = ref.watch(companyVideosProvider(companyId));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('企業動画'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text('動画がありません'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoId = video['id'] as String? ?? '';
              final title = video['title'] as String? ?? 'タイトルなし';
              final description = video['description'] as String? ?? '';
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

              if (videoUrl != null) {
                _initializeVideo(videoId, videoUrl);
              }

              final controller = _controllers[videoId];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動画プレイヤーまたはサムネイル
                    AspectRatio(
                      aspectRatio: 16 / 9,
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
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                    ),
                    // タイトルと説明
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF323232),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(companyVideosProvider(companyId));
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
