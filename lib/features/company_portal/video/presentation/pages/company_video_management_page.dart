// company_portal/video/presentation/pages/company_video_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyVideoManagementPage extends ConsumerWidget {
  const CompanyVideoManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(companyVideosProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/dashboard'),
        ),
        title: const Text('動画管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/company-portal/videos/post'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規動画投稿'),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/videos/list'),
                    icon: Icon(
                      Icons.list,
                      color: ColorPalette.primaryColor,
                    ),
                    label: const Text('動画一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                      side: const BorderSide(
                        color: ColorPalette.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            Text(
              '投稿済み動画',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),
            Expanded(
              child: videosAsync.when(
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
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
                            '投稿済みの動画はありません',
                            style: TextStylePalette.header,
                          ),
                          const SizedBox(height: SpacePalette.sm),
                          Text(
                            '最初の企業紹介動画を投稿しましょう',
                            style: TextStylePalette.subText,
                          ),
                          const SizedBox(height: SpacePalette.lg * 2),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/company-portal/videos/post'),
                            icon: const Icon(Icons.add),
                            label: const Text('最初の動画を投稿'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(SpacePalette.base),
                          leading: Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: ColorPalette.neutral200,
                              borderRadius: BorderRadius.circular(RadiusPalette.base),
                            ),
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 32,
                              color: ColorPalette.neutral500,
                            ),
                          ),
                          title: Text(
                            video['title'] ?? '',
                            style: TextStylePalette.smListTitle,
                          ),
                          subtitle: Text(
                            video['description'] ?? '',
                            style: TextStylePalette.smListLeading,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: ColorPalette.neutral800,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: ColorPalette.neutral800,
                                    ),
                                    const SizedBox(width: SpacePalette.sm),
                                    Text(
                                      '編集',
                                      style: TextStylePalette.normalText,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: SpacePalette.sm),
                                    Text(
                                      '削除',
                                      style: TextStylePalette.normalText.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                context.go('/company-portal/videos/${video['id']}/edit');
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      '削除確認',
                                      style: TextStylePalette.title,
                                    ),
                                    content: Text(
                                      'この動画を削除しますか？',
                                      style: TextStylePalette.normalText,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          'キャンセル',
                                          style: TextStylePalette.normalText.copyWith(
                                            color: ColorPalette.neutral500,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(
                                          '削除',
                                          style: TextStylePalette.normalText.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  try {
                                    await ref.read(companyPortalRepositoryProvider).deleteVideo(video['id']);
                                    ref.invalidate(companyVideosProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '動画を削除しました',
                                            style: TextStylePalette.normalText.copyWith(
                                              color: ColorPalette.neutral0,
                                            ),
                                          ),
                                          backgroundColor: ColorPalette.systemGold,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '削除エラー: $e',
                                            style: TextStylePalette.normalText.copyWith(
                                              color: ColorPalette.neutral0,
                                            ),
                                          ),
                                          backgroundColor: ColorPalette.primaryColor,
                                        ),
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
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: ColorPalette.primaryColor,
                  ),
                ),
                error: (error, _) => Center(
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
                        'エラーが発生しました',
                        style: TextStylePalette.header,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        '$error',
                        style: TextStylePalette.subText,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}