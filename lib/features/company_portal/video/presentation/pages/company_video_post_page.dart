// company_portal/video/presentation/pages/company_video_post_page.dart
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

class CompanyVideoPostPage extends HookConsumerWidget {
  const CompanyVideoPostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final tagsController = useTextEditingController();
    final isVertical = useState(true);
    final isPublic = useState(true);
    final isLoading = useState(false);
    
    // アップロードファイル
    final videoFile = useState<PlatformFile?>(null);
    final thumbnailFile = useState<PlatformFile?>(null);
    final thumbnailUrl = useState<String?>(null);

    // 動画ファイル選択
    final pickVideoFile = useCallback(() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
          withData: true,  // Web版で bytes を取得するために必須
        );

        if (result != null && result.files.isNotEmpty) {
          videoFile.value = result.files.first;
          
          // デバッグ: bytes が取得できているか確認
          print('=== ファイル選択デバッグ ===');
          print('File name: ${result.files.first.name}');
          print('File size: ${result.files.first.size}');
          print('Bytes length: ${result.files.first.bytes?.length}');
          print('Bytes is null: ${result.files.first.bytes == null}');
          print('==================');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '動画を選択しました: ${result.files.first.name}',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGold,
            ),
          );
        }
      } catch (e, stackTrace) {
        print('=== 動画ファイル選択エラー ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        print('==================');
        
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

    // サムネイル画像選択
    final pickThumbnailFile = useCallback(() async {
      try {
        if (kIsWeb) {
          // Web: file_pickerを使用
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true,  // Web版で bytes を取得するために必須
          );

          if (result != null && result.files.isNotEmpty) {
            thumbnailFile.value = result.files.first;
            
            // Web用のプレビューURL生成
            if (result.files.first.bytes != null) {
              // bytes から Blob URL を生成（Webのみ）
              thumbnailUrl.value = null; // プレビューは後で実装
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'サムネイルを選択しました: ${result.files.first.name}',
                  style: TextStylePalette.normalText.copyWith(
                    color: ColorPalette.neutral0,
                  ),
                ),
                backgroundColor: ColorPalette.systemGold,
              ),
            );
          }
        } else {
          // Mobile: image_pickerを使用
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          
          if (image != null) {
            final bytes = await image.readAsBytes();
            thumbnailFile.value = PlatformFile(
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
                backgroundColor: ColorPalette.systemGold,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('=== サムネイル選択エラー ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        print('==================');
        
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

    // 投稿処理
    final postVideo = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      if (videoFile.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '動画ファイルを選択してください',
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
        // FutureProviderを待つ
        final userProfile = await ref.read(currentUserProfileProvider.future);
        final companyId = userProfile?['company_id'] as String?;
        
        if (companyId == null) {
          throw Exception('企業IDが設定されていません。user_profilesテーブルのcompany_idを設定してください。');
        }

        // ===== デバッグコード =====
        print('=== 動画投稿デバッグ ===');
        print('Company ID: $companyId');
        print('Video File: ${videoFile.value?.name}');
        print('Video File size: ${videoFile.value?.size}');
        print('Video File bytes length: ${videoFile.value?.bytes?.length}');
        print('Video File bytes is null: ${videoFile.value?.bytes == null}');
        print('Thumbnail File: ${thumbnailFile.value?.name ?? "なし"}');
        print('==================');
        
        // bytes が null の場合のエラー
        if (videoFile.value?.bytes == null) {
          throw Exception('動画ファイルのデータが読み込めませんでした。ファイルサイズが大きすぎるか、ブラウザのメモリ不足の可能性があります。');
        }
        // ===== デバッグコード終了 =====

        final supabase = Supabase.instance.client;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // ファイル名をサニタイズ（日本語・スペース・特殊文字を除去）
        String sanitizeFileName(String fileName) {
          // 拡張子を分離
          final lastDot = fileName.lastIndexOf('.');
          String name = lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
          String extension = lastDot != -1 ? fileName.substring(lastDot) : '';
          
          // 英数字、ハイフン、アンダースコアのみ残す
          name = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          
          // 連続するアンダースコアを1つに
          name = name.replaceAll(RegExp(r'_+'), '_');
          
          // 先頭と末尾のアンダースコアを削除
          name = name.replaceAll(RegExp(r'^_+|_+$'), '');
          
          // 空の場合は 'file' にする
          if (name.isEmpty) name = 'file';
          
          return '$name$extension';
        }
        
        // 動画アップロード
        final sanitizedVideoName = sanitizeFileName(videoFile.value!.name);
        final videoFileName = '${companyId}_${timestamp}_$sanitizedVideoName';
        final videoPath = 'companies/$companyId/$videoFileName';
        
        print('=== ファイル名サニタイズ ===');
        print('Original: ${videoFile.value!.name}');
        print('Sanitized: $sanitizedVideoName');
        print('Final path: $videoPath');
        print('==================');
        
        await supabase.storage.from('company-videos').uploadBinary(
          videoPath,
          videoFile.value!.bytes!,
          fileOptions: FileOptions(
            contentType: 'video/mp4',
            upsert: false,
          ),
        );

        // サムネイルアップロード（オプション）
        String? thumbnailPath;
        if (thumbnailFile.value != null && thumbnailFile.value!.bytes != null) {
          final sanitizedThumbnailName = sanitizeFileName(thumbnailFile.value!.name);
          final thumbnailFileName = '${companyId}_${timestamp}_thumb_$sanitizedThumbnailName';
          thumbnailPath = 'companies/$companyId/$thumbnailFileName';
          
          await supabase.storage.from('company-thumbnails').uploadBinary(
            thumbnailPath,
            thumbnailFile.value!.bytes!,
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

        // 動画データを作成
        final videoData = {
          'company_id': companyId,
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'vertical': isVertical.value,
          'is_public': isPublic.value,
          'tags': tags,
          'video_path': videoPath,
          'thumbnail_path': thumbnailPath,
          'sort_order': 0,
        };

        await ref.read(companyPortalRepositoryProvider).createVideo(videoData);

        print('=== 動画投稿成功 ===');
        print('Video ID created successfully');
        print('==================');

        // 動画一覧を再取得
        ref.invalidate(companyVideosProvider);
        ref.invalidate(dashboardStatsProvider);

        if (context.mounted) {
          print('Success: 動画を投稿しました');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '動画を投稿しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGold,
            ),
          );
          context.go('/company-portal/videos');
        }
      } catch (e, stackTrace) {
        print('=== 投稿エラー詳細 ===');
        print('Error type: ${e.runtimeType}');
        print('Error message: $e');
        print('Stack trace: $stackTrace');
        print('==================');
        
        if (context.mounted) {
          final errorMessage = '投稿エラー: $e';
          print('Snackbar message: $errorMessage');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
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
      videoFile.value,
      thumbnailFile.value,
    ]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => context.go('/company-portal/videos'),
        ),
        title: const Text('動画投稿'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 動画ファイル選択
              Text(
                '動画ファイル',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              Container(
                height: 220,  // 高さを増やした
                decoration: BoxDecoration(
                  color: ColorPalette.neutral0,
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  border: Border.all(
                    color: videoFile.value != null 
                        ? ColorPalette.systemGold 
                        : ColorPalette.neutral200,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(SpacePalette.base),  // padding追加
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        videoFile.value != null
                            ? Icons.check_circle
                            : Icons.video_file_outlined,
                        size: 64,
                        color: videoFile.value != null
                            ? ColorPalette.systemGold
                            : ColorPalette.neutral400,
                      ),
                      const SizedBox(height: SpacePalette.base),
                      if (videoFile.value != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SpacePalette.sm),
                          child: Text(
                            videoFile.value!.name,
                            style: TextStylePalette.normalText.copyWith(
                              color: ColorPalette.systemGold,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,  // 2行まで表示
                            overflow: TextOverflow.ellipsis,  // オーバーフロー対策
                          ),
                        ),
                        const SizedBox(height: SpacePalette.xs),
                        Text(
                          '${(videoFile.value!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStylePalette.smSubText,
                        ),
                        const SizedBox(height: SpacePalette.sm),
                      ],
                      ElevatedButton.icon(
                        onPressed: pickVideoFile,
                        icon: Icon(
                          videoFile.value != null ? Icons.refresh : Icons.upload,
                        ),
                        label: Text(
                          videoFile.value != null ? '動画を変更' : '動画ファイルを選択',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg),

              // サムネイル画像選択
              Text(
                'サムネイル画像（オプション）',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral0,
                  borderRadius: BorderRadius.circular(RadiusPalette.lg),
                  border: Border.all(
                    color: thumbnailFile.value != null
                        ? ColorPalette.systemGold
                        : ColorPalette.neutral200,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(SpacePalette.base),  // padding追加
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        thumbnailFile.value != null
                            ? Icons.check_circle
                            : Icons.image_outlined,
                        size: 48,
                        color: thumbnailFile.value != null
                            ? ColorPalette.systemGold
                            : ColorPalette.neutral400,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      if (thumbnailFile.value != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SpacePalette.sm),
                          child: Text(
                            thumbnailFile.value!.name,
                            style: TextStylePalette.smSubText.copyWith(
                              color: ColorPalette.systemGold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,  // 1行まで表示
                            overflow: TextOverflow.ellipsis,  // オーバーフロー対策
                          ),
                        ),
                        const SizedBox(height: SpacePalette.sm),
                      ],
                      TextButton.icon(
                        onPressed: pickThumbnailFile,
                        icon: Icon(
                          thumbnailFile.value != null ? Icons.refresh : Icons.add_photo_alternate,
                          size: 20,
                        ),
                        label: Text(
                          thumbnailFile.value != null ? 'サムネイルを変更' : 'サムネイルを選択',
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

              // 投稿ボタン
              ElevatedButton(
                onPressed: isLoading.value ? null : postVideo,
                child: isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorPalette.neutral0,
                        ),
                      )
                    : const Text('投稿'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}