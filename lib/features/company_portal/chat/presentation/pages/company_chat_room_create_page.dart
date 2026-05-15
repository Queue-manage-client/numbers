// features/company_portal/chat/presentation/pages/company_chat_room_create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/chat/presentation/providers/company_chat_provider.dart';
import 'package:numbers/features/company_portal/providers/company_portal_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';


class CompanyChatRoomCreatePage extends HookConsumerWidget {
  const CompanyChatRoomCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    final createChatRoom = useCallback(() async {
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

      // 現在のユーザーIDを取得
      final currentUser = ref.read(currentUserProvider);
      final currentUserId = currentUser?.id;

      isLoading.value = true;

      try {
        await ref.read(companyChatRepositoryProvider).createChatRoom(
              companyId: companyId,
              name: nameController.text.trim(),
              description: descriptionController.text.trim(),
              type: 'group', // 常にグループ
              currentUserId: currentUserId,
            );

        ref.invalidate(companyChatRoomsListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'グループチャットを作成しました',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.systemGold,
            ),
          );
          context.go('/company-portal/chats/list');
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
    }, [nameController, descriptionController]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () { if (Navigator.of(context).canPop()) { context.pop(); } else { context.go("/feed"); } },
        ),
        title: const Text('グループチャット作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ルーム名
              Text(
                'ルーム名',
                style: TextStylePalette.smTitle,
              ),
              const SizedBox(height: SpacePalette.sm),
              TextFormField(
                controller: nameController,
                style: TextStylePalette.normalText,
                decoration: InputDecoration(
                  hintText: '例: 25卒向け情報交換',
                  hintStyle: TextStylePalette.hintText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ルーム名を入力してください';
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
                  hintText: '例: 就活の情報交換をしましょう！',
                  hintStyle: TextStylePalette.hintText,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacePalette.lg),

              // 説明カード
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
                        '作成したグループチャットは、すべてのユーザーに公開されます。\n学生が自由に参加できるオープンなチャットルームです。',
                        style: TextStylePalette.subText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpacePalette.lg * 2),

              // 作成ボタン
              ElevatedButton(
                onPressed: isLoading.value ? null : createChatRoom,
                child: isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorPalette.neutral0,
                        ),
                      )
                    : const Text('作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}