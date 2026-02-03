// admin/presentation/pages/admin_video_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/admin/providers/admin_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AdminVideoManagementPage extends HookConsumerWidget {
  const AdminVideoManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(adminVideosProvider);
    final companiesAsync = ref.watch(adminCompaniesProvider);
    final filter = ref.watch(videoFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('動画管理'),
      ),
      body: Column(
        children: [
          // フィルターバー
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            color: ColorPalette.neutral0,
            child: Column(
              children: [
                // 企業フィルター
                companiesAsync.when(
                  data: (companies) => DropdownButtonFormField<String?>(
                    value: filter.companyId,
                    decoration: const InputDecoration(
                      labelText: '企業でフィルター',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全ての企業')),
                      ...companies.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] ?? '不明'),
                          )),
                    ],
                    onChanged: (value) {
                      ref.read(videoFilterProvider.notifier).state =
                          VideoFilter(companyId: value, isPublic: filter.isPublic);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('企業の読み込みエラー'),
                ),
                const SizedBox(height: SpacePalette.sm),
                // 公開状態フィルター
                Row(
                  children: [
                    Text('公開状態:', style: TextStylePalette.normalText),
                    const SizedBox(width: SpacePalette.sm),
                    _FilterChip(
                      label: '全て',
                      isSelected: filter.isPublic == null,
                      onTap: () {
                        ref.read(videoFilterProvider.notifier).state =
                            VideoFilter(companyId: filter.companyId);
                      },
                    ),
                    const SizedBox(width: SpacePalette.xs),
                    _FilterChip(
                      label: '公開',
                      isSelected: filter.isPublic == true,
                      onTap: () {
                        ref.read(videoFilterProvider.notifier).state =
                            VideoFilter(companyId: filter.companyId, isPublic: true);
                      },
                    ),
                    const SizedBox(width: SpacePalette.xs),
                    _FilterChip(
                      label: '非公開',
                      isSelected: filter.isPublic == false,
                      onTap: () {
                        ref.read(videoFilterProvider.notifier).state =
                            VideoFilter(companyId: filter.companyId, isPublic: false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 動画リスト
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminVideosProvider);
              },
              child: videosAsync.when(
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        '動画が見つかりません',
                        style: TextStylePalette.subText,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(SpacePalette.base),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return _VideoCard(
                        video: video,
                        onToggleVisibility: () async {
                          final isPublic = video['is_public'] == true;
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            await repo.updateVideoVisibility(video['id'], !isPublic);
                            ref.invalidate(adminVideosProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isPublic ? '動画を非公開にしました' : '動画を公開しました',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('エラー: $e')),
                              );
                            }
                          }
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('削除確認'),
                              content: const Text('この動画を削除しますか？この操作は元に戻せません。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('削除'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              final repo = ref.read(adminRepositoryProvider);
                              await repo.deleteVideo(video['id']);
                              ref.invalidate(adminVideosProvider);
                              ref.invalidate(adminDashboardStatsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('動画を削除しました')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('エラー: $e')),
                                );
                              }
                            }
                          }
                        },
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
                  child: Text(
                    'エラー: $error',
                    style: TextStylePalette.subText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: SpacePalette.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral200,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
        ),
        child: Text(
          label,
          style: TextStylePalette.normalText.copyWith(
            color: isSelected ? ColorPalette.neutral0 : ColorPalette.neutral800,
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.video,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = video['is_public'] == true;
    final company = video['companies'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Row(
          children: [
            // サムネイル
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: ColorPalette.neutral200,
                borderRadius: BorderRadius.circular(RadiusPalette.mini),
              ),
              child: Icon(
                Icons.video_library,
                color: ColorPalette.neutral500,
              ),
            ),
            const SizedBox(width: SpacePalette.base),

            // 動画情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video['title'] ?? '無題',
                          style: TextStylePalette.smListTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _VisibilityBadge(isPublic: isPublic),
                    ],
                  ),
                  const SizedBox(height: SpacePalette.xs),
                  Text(
                    '企業: ${company?['name'] ?? '不明'}',
                    style: TextStylePalette.subText,
                  ),
                  if (video['description'] != null)
                    Text(
                      video['description'],
                      style: TextStylePalette.subText.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // アクションメニュー
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  onToggleVisibility();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isPublic ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: SpacePalette.sm),
                      Text(isPublic ? '非公開にする' : '公開する'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: SpacePalette.sm),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final bool isPublic;

  const _VisibilityBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isPublic
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
        border: Border.all(
          color: isPublic
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Text(
        isPublic ? '公開' : '非公開',
        style: TextStylePalette.subText.copyWith(
          fontSize: 10,
          color: isPublic ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
