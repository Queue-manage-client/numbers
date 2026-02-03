// company_portal/video/presentation/pages/company_video_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

// 動画詳細取得Provider
final videoByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, videoId) async {
  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getVideoById(videoId);
});

class CompanyVideoEditPage extends HookConsumerWidget {
  final String videoId;

  const CompanyVideoEditPage({
    super.key,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final tagsController = useTextEditingController();
    final isVertical = useState(true);
    final isPublic = useState(true);
    final isLoading = useState(false);
    final isDataLoaded = useState(false);
    
    // 新しいサムネイル
    final newThumbnailFile = useState<PlatformFile?>(null);
    
    // 既存の動画データ
    final videoAsync = ref.watch(videoByIdProvider(videoId));

    // データをフォームにセット
    useEffect(() {
      videoAsync.whenData((video) {
        if (video != null && !isDataLoaded.value) {
          titleController.text = video['title'] ?? '';
          descriptionController.text = video['description'] ?? '';
          
          final tags = video['tags'] as List<dynamic>?;
          if (tags != null && tags.isNotEmpty) {
            tagsController.text = tags.join(', ');
          }
          
          isVertical.value = video['vertical'] ?? true;
          isPublic.value = video['is_public'] ?? true;
          isDataLoaded.value = true;
        }
      });
      return null;
    }, [videoAsync]);

    // サムネイル画像選択
    final pickThumbnailFile = useCallback(() async {
      try {
        if (kIsWeb) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true
          );

          if (result != null && result.files.isNotEmpty) {
            newThumbnailFile.value = result.files.first;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'サムネイルを選択しました: ${result.files.first.name}',
                  style: TextStylePalette.normalText.copyWith(
                    color: ColorPalette.neutral0,
                  ),
                ),
                backgroundColor: ColorPalette.systemGreen,
              ),
            );
          }
        } else {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          
          if (image != null) {
            final bytes = await image.readAsBytes();
            newThumbnailFile.value = PlatformFile(
              name: image.name,
              size: bytes.length,
              bytes: bytes,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'サムネイルを選択しました: ${image.name}',
                  style: TextStylePalette.normalText.copyWith(
                    color: ColorPalette.neutral0,
                  ),
                ),
                backgroundColor: ColorPalette.systemGreen,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ファイル選択エラー: $e',
              style: TextStylePalette.normalText.copyWith(
                color: ColorPalette.neutral0,
              ),
            ),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
      }
    }, []);

    // 更新処理
    final updateVideo = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      final companyId = ref.read(currentCompanyIdProvider);
      if (companyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '企業IDが取得できません',
              style: TextStylePalette.normalText.copyWith(
                color: ColorPalette.neutral0,
              ),
            ),
            backgroundColor: ColorPalette.primaryColor,
          ),
        );
        return;
      }

      isLoading.value = true;

      try {
        final supabase = Supabase.instance.client;
        
        // 新しいサムネイルのアップロード
        String? newThumbnailPath;
        if (newThumbnailFile.value != null && newThumbnailFile.value!.bytes != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final thumbnailFileName = '${companyId}_${timestamp}_thumb_${newThumbnailFile.value!.name}';
          newThumbnailPath = 'companies/$companyId/$thumbnailFileName';
          
          await supabase.storage.from('company-thumbnails').uploadBinary(
            newThumbnailPath,
            newThumbnailFile.value!.bytes!,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
        }

        // タグをカンマ区切りで配列に変換
        final tagsText = tagsController.text.trim();
        final tags = tagsText.isEmpty
            ? <String>[]
            : tagsText.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

        // 更新データを作成
        final updateData = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'vertical': isVertical.value,
          'is_public': isPublic.value,
          'tags': tags,
        };

        // 新しいサムネイルがあれば追加
        if (newThumbnailPath != null) {
          updateData['thumbnail_path'] = newThumbnailPath;
        }

        await ref.read(companyPortalRepositoryProvider).updateVideo(videoId, updateData);

        // 動画一覧を再取得
        ref.invalidate(companyVideosProvider);
        ref.invalidate(videoByIdProvider(videoId));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '動画を更新しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGreen,
            ),
          );
          context.go('/company-portal/videos/list');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '更新エラー: $e',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }, [
      titleController,
      descriptionController,
      tagsController,
      isVertical.value,
      isPublic.value,
      newThumbnailFile.value,
      videoId,
    ]);

    // 削除処理
    final deleteVideo = useCallback(() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            '削除確認',
            style: TextStylePalette.title,
          ),
          content: Text(
            'この動画を削除しますか？\nこの操作は取り消せません。',
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

      if (confirmed == true) {
        try {
          await ref.read(companyPortalRepositoryProvider).deleteVideo(videoId);
          ref.invalidate(companyVideosProvider);
          ref.invalidate(dashboardStatsProvider);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '動画を削除しました',
                  style: TextStylePalette.normalText.copyWith(
                    color: ColorPalette.neutral0,
                  ),
                ),
                backgroundColor: ColorPalette.systemGreen,
              ),
            );
            context.go('/company-portal/videos/list');
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
    }, [videoId]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/videos/list'),
        ),
        title: const Text('動画編集'),
      ),
      body: videoAsync.when(
        data: (video) {
          if (video == null) {
            return Center(
              child: Text(
                '動画が見つかりません',
                style: TextStylePalette.header,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 動画プレビュー
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral200,
                      borderRadius: BorderRadius.circular(RadiusPalette.lg),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: ColorPalette.neutral500,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    '※動画ファイルの変更はできません',
                    style: TextStylePalette.smSubText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // サムネイル画像選択
                  Text(
                    'サムネイル画像',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: ColorPalette.neutral0,
                      borderRadius: BorderRadius.circular(RadiusPalette.lg),
                      border: Border.all(
                        color: newThumbnailFile.value != null
                            ? ColorPalette.systemGreen
                            : ColorPalette.neutral200,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            newThumbnailFile.value != null
                                ? Icons.check_circle
                                : Icons.image_outlined,
                            size: 48,
                            color: newThumbnailFile.value != null
                                ? ColorPalette.systemGreen
                                : ColorPalette.neutral400,
                          ),
                          const SizedBox(height: SpacePalette.sm),
                          if (newThumbnailFile.value != null) ...[
                            Text(
                              '新しいサムネイル: ${newThumbnailFile.value!.name}',
                              style: TextStylePalette.smSubText.copyWith(
                                color: ColorPalette.systemGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SpacePalette.sm),
                          ] else if (video['thumbnail_path'] != null) ...[
                            Text(
                              '現在のサムネイル設定済み',
                              style: TextStylePalette.smSubText,
                            ),
                            const SizedBox(height: SpacePalette.sm),
                          ],
                          TextButton.icon(
                            onPressed: pickThumbnailFile,
                            icon: Icon(
                              newThumbnailFile.value != null || video['thumbnail_path'] != null
                                  ? Icons.refresh
                                  : Icons.add_photo_alternate,
                              size: 20,
                            ),
                            label: Text(
                              newThumbnailFile.value != null || video['thumbnail_path'] != null
                                  ? 'サムネイルを変更'
                                  : 'サムネイルを追加',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg),

                  // タイトル
                  Text(
                    'タイトル',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: titleController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '動画のタイトルを入力',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 説明
                  Text(
                    '説明',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: descriptionController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '動画の説明を入力',
                      hintStyle: TextStylePalette.hintText,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // タグ
                  Text(
                    'タグ',
                    style: TextStylePalette.smTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  TextFormField(
                    controller: tagsController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '例: IT, エンジニア, 新卒',
                      hintStyle: TextStylePalette.hintText,
                      helperText: 'カンマ区切りで入力してください',
                      helperStyle: TextStylePalette.smSubText,
                    ),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 設定
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            '縦型動画',
                            style: TextStylePalette.normalText,
                          ),
                          subtitle: Text(
                            'TikTok形式の縦型動画として表示',
                            style: TextStylePalette.smSubText,
                          ),
                          value: isVertical.value,
                          onChanged: (value) => isVertical.value = value,
                          activeColor: ColorPalette.primaryColor,
                        ),
                        Divider(
                          height: 1,
                          color: ColorPalette.neutral200,
                        ),
                        SwitchListTile(
                          title: Text(
                            '公開',
                            style: TextStylePalette.normalText,
                          ),
                          subtitle: Text(
                            'フィードに表示します',
                            style: TextStylePalette.smSubText,
                          ),
                          value: isPublic.value,
                          onChanged: (value) => isPublic.value = value,
                          activeColor: ColorPalette.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SpacePalette.lg * 2),

                  // 更新ボタン
                  ElevatedButton(
                    onPressed: isLoading.value ? null : updateVideo,
                    child: isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : const Text('更新'),
                  ),
                  const SizedBox(height: SpacePalette.base),

                  // 削除ボタン
                  OutlinedButton(
                    onPressed: deleteVideo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: const Text('削除'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryColor,
          ),
        ),
        error: (error, _) => Center(
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
                  'エラーが発生しました',
                  style: TextStylePalette.header,
                ),
                const SizedBox(height: SpacePalette.sm),
                Text(
                  '$error',
                  style: TextStylePalette.subText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacePalette.lg),
                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(videoByIdProvider(videoId));
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
      ),
    );
  }
}