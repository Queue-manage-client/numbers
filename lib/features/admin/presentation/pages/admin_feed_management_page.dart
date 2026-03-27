// admin/presentation/pages/admin_feed_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/theme/app_theme.dart';

// ========== Providers ==========

final _supabase = Supabase.instance.client;

final adminBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await _supabase
      .from('feed_banners')
      .select()
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(response as List);
});

final adminSectionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await _supabase
      .from('feed_sections')
      .select()
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(response as List);
});

final adminAllVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await _supabase
      .from('company_videos')
      .select('*, companies(*)')
      .eq('is_public', true)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response as List);
});

final adminSectionVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sectionId) async {
  final response = await _supabase
      .from('feed_section_videos')
      .select('*, company_videos(*, companies(*))')
      .eq('section_id', sectionId)
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(response as List);
});

// ========== Main Page ==========

class AdminFeedManagementPage extends ConsumerWidget {
  const AdminFeedManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ColorPalette.neutral900,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
            onPressed: () => context.go('/admin/dashboard'),
          ),
          title: const Text('フィード管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'バナー'),
              Tab(text: '特集セクション'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BannerManagementTab(),
            _SectionManagementTab(),
          ],
        ),
      ),
    );
  }
}

// ========== Banner Management ==========

class _BannerManagementTab extends ConsumerWidget {
  const _BannerManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: ElevatedButton.icon(
            onPressed: () => _showAddBannerDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('バナー追加'),
          ),
        ),
        Expanded(
          child: bannersAsync.when(
            data: (banners) {
              if (banners.isEmpty) {
                return Center(child: Text('バナーがありません', style: TextStylePalette.subText));
              }
              return ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                itemCount: banners.length,
                onReorder: (oldIndex, newIndex) => _reorderBanners(ref, banners, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return Card(
                    key: ValueKey(banner['id']),
                    margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                    child: ListTile(
                      leading: banner['image_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                banner['image_url'],
                                width: 60,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60, height: 42,
                                  color: ColorPalette.neutral600,
                                  child: const Icon(Icons.image, color: ColorPalette.neutral400),
                                ),
                              ),
                            )
                          : null,
                      title: Text('バナー ${index + 1}', style: TextStylePalette.smListTitle),
                      subtitle: Text(
                        banner['is_active'] == true ? '公開中' : '非公開',
                        style: TextStylePalette.smSubText.copyWith(
                          color: banner['is_active'] == true ? Colors.green : ColorPalette.neutral400,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              banner['is_active'] == true ? Icons.visibility : Icons.visibility_off,
                              color: ColorPalette.neutral400,
                              size: 20,
                            ),
                            onPressed: () => _toggleBannerActive(ref, banner),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteBanner(context, ref, banner['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e', style: TextStylePalette.subText)),
          ),
        ),
      ],
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('バナー追加', style: TextStylePalette.smTitle),
        content: TextField(
          controller: urlController,
          style: TextStylePalette.normalText,
          decoration: const InputDecoration(hintText: '画像URLを入力'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル', style: TextStyle(color: ColorPalette.neutral400)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (urlController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _supabase.from('feed_banners').insert({
                'image_url': urlController.text.trim(),
                'sort_order': 999,
              });
              ref.invalidate(adminBannersProvider);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBannerActive(WidgetRef ref, Map<String, dynamic> banner) async {
    await _supabase.from('feed_banners').update({
      'is_active': !(banner['is_active'] as bool),
    }).eq('id', banner['id']);
    ref.invalidate(adminBannersProvider);
  }

  Future<void> _deleteBanner(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('削除確認', style: TextStylePalette.smTitle),
        content: Text('このバナーを削除しますか？', style: TextStylePalette.normalText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.from('feed_banners').delete().eq('id', id);
      ref.invalidate(adminBannersProvider);
    }
  }

  Future<void> _reorderBanners(WidgetRef ref, List<Map<String, dynamic>> banners, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = banners.removeAt(oldIndex);
    banners.insert(newIndex, item);
    for (int i = 0; i < banners.length; i++) {
      await _supabase.from('feed_banners').update({'sort_order': i}).eq('id', banners[i]['id']);
    }
    ref.invalidate(adminBannersProvider);
  }
}

// ========== Section Management ==========

class _SectionManagementTab extends ConsumerWidget {
  const _SectionManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(adminSectionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: ElevatedButton.icon(
            onPressed: () => _showAddSectionDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('セクション追加'),
          ),
        ),
        Expanded(
          child: sectionsAsync.when(
            data: (sections) {
              if (sections.isEmpty) {
                return Center(child: Text('セクションがありません', style: TextStylePalette.subText));
              }
              return ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
                itemCount: sections.length,
                onReorder: (oldIndex, newIndex) => _reorderSections(ref, sections, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _SectionCard(
                    key: ValueKey(section['id']),
                    section: section,
                    isHighlight: index == 0,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e', style: TextStylePalette.subText)),
          ),
        ),
      ],
    );
  }

  Future<void> _reorderSections(WidgetRef ref, List<Map<String, dynamic>> sections, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    for (int i = 0; i < sections.length; i++) {
      await _supabase.from('feed_sections').update({'sort_order': i}).eq('id', sections[i]['id']);
    }
    ref.invalidate(adminSectionsProvider);
  }

  void _showAddSectionDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String selectedType = 'video';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ColorPalette.neutral800,
          title: Text('セクション追加', style: TextStylePalette.smTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStylePalette.normalText,
                decoration: const InputDecoration(hintText: 'セクションタイトル（例: おすすめ企業）'),
              ),
              const SizedBox(height: SpacePalette.base),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: ColorPalette.neutral800,
                style: TextStylePalette.normalText,
                decoration: const InputDecoration(
                  labelText: 'セクションタイプ',
                ),
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('動画セクション')),
                  DropdownMenuItem(value: 'company', child: Text('企業セクション')),
                  DropdownMenuItem(value: 'watched_history', child: Text('視聴履歴セクション')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル', style: TextStyle(color: ColorPalette.neutral400)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context);
                await _supabase.from('feed_sections').insert({
                  'title': titleController.text.trim(),
                  'section_type': selectedType,
                  'sort_order': 999,
                });
                ref.invalidate(adminSectionsProvider);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends ConsumerWidget {
  final Map<String, dynamic> section;
  final bool isHighlight;

  const _SectionCard({super.key, required this.section, this.isHighlight = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionId = section['id'] as String;
    final videosAsync = ref.watch(adminSectionVideosProvider(sectionId));

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.base),
      child: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlight)
              Container(
                margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacePalette.sm,
                  vertical: SpacePalette.xs,
                ),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(RadiusPalette.mini),
                  border: Border.all(color: ColorPalette.primaryColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: ColorPalette.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '注目セクション（縦長カードで表示）',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size12,
                        fontVariations: const [FontVariation('wght', 700)],
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(Icons.drag_handle, size: 20, color: ColorPalette.neutral500),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: Row(
                    children: [
                      Text(section['title'] ?? '', style: TextStylePalette.smHeader),
                      const SizedBox(width: SpacePalette.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _sectionTypeColor(section['section_type'] as String?),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _sectionTypeLabel(section['section_type'] as String?),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: ColorPalette.neutral400),
                  onPressed: () => _editTitle(context, ref),
                ),
                IconButton(
                  icon: Icon(
                    section['is_active'] == true ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: ColorPalette.neutral400,
                  ),
                  onPressed: () => _toggleActive(ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            Text(
              section['is_active'] == true ? '公開中' : '非公開',
              style: TextStylePalette.smSubText.copyWith(
                color: section['is_active'] == true ? Colors.green : ColorPalette.neutral400,
              ),
            ),
            const SizedBox(height: SpacePalette.sm),
            // 動画一覧（並び替え可能）
            videosAsync.when(
              data: (videos) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('動画: ${videos.length}件', style: TextStylePalette.subText),
                    const SizedBox(height: SpacePalette.sm),
                    if (videos.isNotEmpty)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) =>
                            _reorderVideos(ref, sectionId, videos, oldIndex, newIndex),
                        children: [
                          for (int i = 0; i < videos.length; i++)
                            _buildVideoItem(context, ref, sectionId, videos[i], i, isHighlight),
                        ],
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: SpacePalette.sm),
            OutlinedButton.icon(
              onPressed: () => _showAddVideoDialog(context, ref, sectionId),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('動画を追加'),
            ),
          ],
        ),
      ),
    );
  }

  static String _sectionTypeLabel(String? type) {
    switch (type) {
      case 'company': return '企業';
      case 'watched_history': return '視聴履歴';
      case 'video':
      default: return '動画';
    }
  }

  static Color _sectionTypeColor(String? type) {
    switch (type) {
      case 'company': return Colors.blue;
      case 'watched_history': return Colors.orange;
      case 'video':
      default: return Colors.green;
    }
  }

  Widget _buildVideoItem(
    BuildContext context,
    WidgetRef ref,
    String sectionId,
    Map<String, dynamic> sv,
    int index,
    bool isHighlight,
  ) {
    final video = sv['company_videos'] as Map<String, dynamic>?;
    final company = video?['companies'] as Map<String, dynamic>?;
    final svId = sv['id'] as String;
    final thumbUrl = sv['thumbnail_url'] as String?;
    final highlightThumbUrl = sv['highlight_thumbnail_url'] as String?;

    return Container(
      key: ValueKey(svId),
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      padding: const EdgeInsets.all(SpacePalette.sm),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル行
          Row(
            children: [
              Icon(Icons.drag_handle, size: 18, color: ColorPalette.neutral500),
              const SizedBox(width: SpacePalette.sm),
              Expanded(
                child: Text(
                  '${company?['name'] ?? '?'} - ${video?['title'] ?? '?'}',
                  style: TextStylePalette.smText,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, size: 18, color: Colors.red),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await _supabase.from('feed_section_videos').delete().eq('id', svId);
                  ref.invalidate(adminSectionVideosProvider(sectionId));
                },
              ),
            ],
          ),
          const SizedBox(height: SpacePalette.sm),
          // サムネイル設定行
          Row(
            children: [
              if (isHighlight)
                // 注目セクション: 縦長サムネイルのみ
                _ThumbnailSlot(
                  label: '縦長',
                  url: highlightThumbUrl,
                  width: 52,
                  height: 80,
                  onUpload: () => _uploadThumbnail(
                    context, ref, sectionId, svId, 'highlight_thumbnail_url',
                  ),
                )
              else
                // 通常セクション: 横長サムネイルのみ
                _ThumbnailSlot(
                  label: '横長',
                  url: thumbUrl,
                  width: 80,
                  height: 52,
                  onUpload: () => _uploadThumbnail(
                    context, ref, sectionId, svId, 'thumbnail_url',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reorderVideos(
    WidgetRef ref,
    String sectionId,
    List<Map<String, dynamic>> videos,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final item = videos.removeAt(oldIndex);
    videos.insert(newIndex, item);
    for (int i = 0; i < videos.length; i++) {
      await _supabase
          .from('feed_section_videos')
          .update({'sort_order': i})
          .eq('id', videos[i]['id']);
    }
    ref.invalidate(adminSectionVideosProvider(sectionId));
  }

  Future<void> _uploadThumbnail(
    BuildContext context,
    WidgetRef ref,
    String sectionId,
    String svId,
    String column,
  ) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$sectionId/${timestamp}_${image.name}';

      await _supabase.storage.from('section-thumbnails').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = _supabase.storage
          .from('section-thumbnails')
          .getPublicUrl(path);

      await _supabase
          .from('feed_section_videos')
          .update({column: publicUrl})
          .eq('id', svId);

      ref.invalidate(adminSectionVideosProvider(sectionId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サムネイルを設定しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロード失敗: $e')),
        );
      }
    }
  }

  void _editTitle(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: section['title']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('タイトル編集', style: TextStylePalette.smTitle),
        content: TextField(
          controller: controller,
          style: TextStylePalette.normalText,
          decoration: const InputDecoration(hintText: 'タイトルを入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _supabase.from('feed_sections').update({'title': controller.text.trim()}).eq('id', section['id']);
              ref.invalidate(adminSectionsProvider);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(WidgetRef ref) async {
    await _supabase.from('feed_sections').update({
      'is_active': !(section['is_active'] as bool),
    }).eq('id', section['id']);
    ref.invalidate(adminSectionsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorPalette.neutral800,
        title: Text('削除確認', style: TextStylePalette.smTitle),
        content: Text('このセクションを削除しますか？', style: TextStylePalette.normalText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.from('feed_sections').delete().eq('id', section['id']);
      ref.invalidate(adminSectionsProvider);
    }
  }

  void _showAddVideoDialog(BuildContext context, WidgetRef ref, String sectionId) {
    final allVideosAsync = ref.read(adminAllVideosProvider);
    allVideosAsync.whenData((videos) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ColorPalette.neutral800,
          title: Text('動画を選択', style: TextStylePalette.smTitle),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                final company = video['companies'] as Map<String, dynamic>?;
                return ListTile(
                  title: Text(video['title'] ?? '', style: TextStylePalette.smListTitle),
                  subtitle: Text(company?['name'] ?? '', style: TextStylePalette.smSubText),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _supabase.from('feed_section_videos').insert({
                        'section_id': sectionId,
                        'video_id': video['id'],
                        'sort_order': 999,
                      });
                      ref.invalidate(adminSectionVideosProvider(sectionId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('この動画は既に追加されています')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// サムネイルスロット（プレビュー + アップロードボタン）
class _ThumbnailSlot extends StatelessWidget {
  final String label;
  final String? url;
  final double width;
  final double height;
  final VoidCallback onUpload;

  const _ThumbnailSlot({
    required this.label,
    required this.url,
    required this.width,
    required this.height,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: ColorPalette.neutral600,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: url != null ? ColorPalette.primaryColor : ColorPalette.neutral500,
                width: url != null ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: url != null && url!.isNotEmpty
                ? Image.network(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 20,
                      color: ColorPalette.neutral400,
                    ),
                  )
                : const Icon(
                    Icons.add_photo_alternate,
                    size: 20,
                    color: ColorPalette.neutral400,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: ColorPalette.neutral400,
            ),
          ),
        ],
      ),
    );
  }
}
