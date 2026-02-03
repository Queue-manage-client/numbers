// company/presentation/pages/company_video_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
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

    // URLの検証
    if (videoUrl.isEmpty || !(Uri.tryParse(videoUrl)?.hasAbsolutePath ?? false)) {
      print('無効なビデオURL (videoId: $videoId): $videoUrl');
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controllers[videoId] = controller;
      
      controller.initialize().then((_) {
        if (!mounted) return;
        
        // 初期化成功後の状態確認
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
        // ビデオの初期化に失敗した場合（フォーマットエラーなど）
        print('ビデオ初期化エラー (videoId: $videoId, URL: $videoUrl): $error');
        print('スタックトレース: $stackTrace');
        // エラーが発生したコントローラーを削除
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
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: const Text('企業動画'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
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

              if (videoUrl != null && videoUrl.isNotEmpty) {
                // URLの検証を追加
                final uri = Uri.tryParse(videoUrl);
                if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                  _initializeVideo(videoId, videoUrl);
                } else {
                  print('無効なビデオURL形式 (videoId: $videoId): $videoUrl');
                }
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.video_library,
                                          color: Colors.grey,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.video_library,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  ),
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
