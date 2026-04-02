// features/user/chat/presentation/pages/group_chat_create_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:numbers/features/user/chat/presentation/providers/chat_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

/// デフォルトチャットアイコンのアセットパス一覧
const List<String> defaultChatIconAssets = [
  'assets/images/chat11.png',
  'assets/images/chat12.png',
  'assets/images/chat13.png',
  'assets/images/chat14.png',
  'assets/images/chat15.png',
  'assets/images/chat16.png',
  'assets/images/chat17.png',
  'assets/images/chat18.png',
  'assets/images/chat19.png',
  'assets/images/chat20.png',
];

/// デフォルトアイコンキー（chat11～chat20）からアセットパスを取得
String? getDefaultChatIconAsset(String key) {
  final path = 'assets/images/$key.png';
  if (defaultChatIconAssets.contains(path)) return path;
  return null;
}

/// アイコンURLに基づいてチャットアイコンWidgetを生成するヘルパー
Widget buildChatIconWidget(String? iconUrl, {double radius = 20}) {
  if (iconUrl == null || iconUrl.isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: ColorPalette.primaryColor,
      child: Icon(Icons.group, color: ColorPalette.neutral0, size: radius),
    );
  }
  // デフォルトアセット画像（chat11～chat20）
  final assetPath = getDefaultChatIconAsset(iconUrl);
  if (assetPath != null) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(assetPath),
      backgroundColor: ColorPalette.neutral600,
    );
  }
  // 旧形式のdefault_XX（後方互換）
  if (iconUrl.startsWith('default_')) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: ColorPalette.primaryColor,
      child: Icon(Icons.group, color: ColorPalette.neutral0, size: radius),
    );
  }
  // カスタムアップロード画像（ネットワークURL）
  return CircleAvatar(
    radius: radius,
    backgroundImage: NetworkImage(iconUrl),
    backgroundColor: ColorPalette.neutral600,
    child: const SizedBox.shrink(),
  );
}

class GroupChatCreatePage extends HookConsumerWidget {
  const GroupChatCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);
    final selectedDefaultIcon = useState<String>('chat11');
    final customIconBytes = useState<Uint8List?>(null);
    final customIconFileName = useState<String?>(null);

    // カスタム画像ピック
    final pickCustomImage = useCallback(() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          customIconBytes.value = bytes;
          customIconFileName.value = image.name;
          selectedDefaultIcon.value = '';
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '画像の選択に失敗しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      }
    }, []);

    // グループ作成
    final createGroup = useCallback(() async {
      if (!formKey.currentState!.validate()) return;

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ログインが必要です',
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
        String? iconUrl;

        // カスタム画像の場合: Storageにアップロード
        if (customIconBytes.value != null) {
          iconUrl = await ref.read(chatRepositoryProvider).uploadChatIcon(
            userId: currentUser.id,
            imageBytes: customIconBytes.value!,
            fileName: customIconFileName.value ?? 'icon.jpg',
          );
        } else if (selectedDefaultIcon.value.isNotEmpty) {
          // デフォルトアイコンの場合: キーをそのまま保存
          iconUrl = selectedDefaultIcon.value;
        }

        final roomId = await ref.read(chatRepositoryProvider).createUserGroupChat(
          userId: currentUser.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          iconUrl: iconUrl,
        );

        ref.invalidate(allGroupChatsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'グループチャットを作成しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGreen,
            ),
          );
          Navigator.of(context).pop(true);
          context.push('/chats/$roomId');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '作成エラー: $e',
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
    }, [nameController, descriptionController, customIconBytes, selectedDefaultIcon]);

    // 選択中のアイコンプレビュー
    Widget buildIconPreview() {
      if (customIconBytes.value != null) {
        return CircleAvatar(
          radius: 40,
          backgroundImage: MemoryImage(customIconBytes.value!),
          backgroundColor: ColorPalette.neutral600,
        );
      }
      if (selectedDefaultIcon.value.isNotEmpty) {
        return buildChatIconWidget(selectedDefaultIcon.value, radius: 40);
      }
      return CircleAvatar(
        radius: 40,
        backgroundColor: ColorPalette.neutral600,
        child: Icon(Icons.group, color: ColorPalette.neutral400, size: 40),
      );
    }

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('グループ作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アイコンプレビュー
              Center(
                child: GestureDetector(
                  onTap: pickCustomImage,
                  child: Stack(
                    children: [
                      buildIconPreview(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorPalette.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ColorPalette.neutral900,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: ColorPalette.neutral900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.sm),
              Center(
                child: Text(
                  'アイコンを選択',
                  style: TextStylePalette.subText,
                ),
              ),
              const SizedBox(height: SpacePalette.lg),

              // デフォルトアイコングリッド
              Text(
                'デフォルトアイコン',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: SpacePalette.sm,
                  crossAxisSpacing: SpacePalette.sm,
                ),
                itemCount: defaultChatIconAssets.length,
                itemBuilder: (context, index) {
                  final assetPath = defaultChatIconAssets[index];
                  // "assets/images/chat11.png" → "chat11"
                  final key = assetPath.split('/').last.replaceAll('.png', '');
                  final isSelected = customIconBytes.value == null &&
                      selectedDefaultIcon.value == key;

                  return GestureDetector(
                    onTap: () {
                      selectedDefaultIcon.value = key;
                      customIconBytes.value = null;
                      customIconFileName.value = null;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: ColorPalette.primaryColor,
                                width: 3,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(assetPath),
                        backgroundColor: ColorPalette.neutral600,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: SpacePalette.sm),

              // カスタム画像選択ボタン
              OutlinedButton.icon(
                onPressed: pickCustomImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('写真から選択'),
              ),
              const SizedBox(height: SpacePalette.lg),

              // グループ名
              Text(
                'グループ名',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: nameController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: 就活仲間の集まり',
                  hintStyle: TextStylePalette.hintText,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'グループ名を入力してください';
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
                  hintText: '例: 就活の情報共有グループです',
                  hintStyle: TextStylePalette.hintText,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.lg),

              // 情報カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: ColorPalette.neutral500,
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          Text(
                            'グループチャットについて',
                            style: TextStylePalette.smTitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        '作成したグループチャットは、すべてのユーザーに公開されます。\n誰でも自由に参加できるオープンなチャットルームです。',
                        style: TextStylePalette.subText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg * 2),

              // 作成ボタン
              ElevatedButton(
                onPressed: isLoading.value ? null : createGroup,
                child: isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorPalette.neutral0,
                        ),
                      )
                    : const Text('グループを作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
