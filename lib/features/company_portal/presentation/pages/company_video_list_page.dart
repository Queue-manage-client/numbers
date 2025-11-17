import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/presentation/providers/company_portal_provider.dart';

class CompanyVideoListManagementPage extends ConsumerWidget {
  const CompanyVideoListManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(companyVideosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('動画一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/company-portal/videos/post'),
          ),
        ],
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '投稿済みの動画はありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/company-portal/videos/post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: const Text('最初の動画を投稿'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFF323232),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_outline, size: 32),
                  ),
                  title: Text(
                    video['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF323232),
                    ),
                  ),
                  subtitle: Text(
                    video['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF323232)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('編集'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('削除'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.go('/company-portal/videos/${video['id']}/edit');
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('削除確認'),
                            content: const Text('この動画を削除しますか?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('削除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          try {
                            await ref.read(companyPortalRepositoryProvider).deleteVideo(video['id']);
                            ref.invalidate(companyVideosProvider);
                            ref.invalidate(dashboardStatsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('動画を削除しました')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('削除エラー: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF323232)),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
