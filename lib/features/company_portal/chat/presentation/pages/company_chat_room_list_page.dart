// features/company_portal/chat/presentation/pages/company_chat_room_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/company_portal/chat/presentation/providers/company_chat_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyChatRoomListPage extends ConsumerWidget {
  const CompanyChatRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(companyChatRoomsListProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorPalette.neutral0,
          ),
          onPressed: () { if (Navigator.of(context).canPop()) { context.pop(); } else { context.go("/feed"); } },
        ),
        title: const Text('チャットルーム一覧'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: ColorPalette.neutral0,
            ),
            onPressed: () => context.go('/company-portal/chats/create'),
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacePalette.base),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: ColorPalette.neutral400,
                    ),
                    const SizedBox(height: SpacePalette.lg),
                    Text(
                      'チャットルームはありません',
                      style: TextStylePalette.header,
                    ),
                    const SizedBox(height: SpacePalette.sm),
                    Text(
                      '最初のチャットルームを作成しましょう',
                      style: TextStylePalette.subText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SpacePalette.lg * 2),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/company-portal/chats/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('最初のチャットルームを作成'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              final isGroup = room['room_type'] == 'group'; // ✅ type → room_type
              final members = room['chat_room_members'] as List?;
              final memberCount = members?.length ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(SpacePalette.base),
                  leading: CircleAvatar(
                    backgroundColor: ColorPalette.primaryColor,
                    child: Icon(
                      isGroup ? Icons.group : Icons.person,
                      color: ColorPalette.neutral0,
                    ),
                  ),
                  title: Text(
                    room['name'] ?? 'チャットルーム', // ✅ nameカラムを使用
                    style: TextStylePalette.smListTitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacePalette.xs),
                      Text(
                        isGroup ? 'グループチャット' : 'ダイレクトメッセージ',
                        style: TextStylePalette.smListLeading,
                      ),
                      const SizedBox(height: SpacePalette.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: ColorPalette.neutral500,
                          ),
                          const SizedBox(width: SpacePalette.xs),
                          Text(
                            '$memberCount人',
                            style: TextStylePalette.smSubText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: ColorPalette.neutral400,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat,
                              size: 20,
                              color: ColorPalette.neutral400,
                            ),
                            const SizedBox(width: SpacePalette.sm),
                            Text(
                              '開く',
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
                      if (value == 'open') {
                        context.go('/company-portal/chats/${room['id']}');
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '削除確認',
                              style: TextStylePalette.title,
                            ),
                            content: Text(
                              'このチャットルームを削除しますか？',
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
                            await ref
                                .read(companyChatRepositoryProvider)
                                .deleteChatRoom(room['id']);
                            ref.invalidate(companyChatRoomsListProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'チャットルームを削除しました',
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
                  onTap: () {
                    context.go('/company-portal/chats/${room['id']}');
                  },
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
                    ref.invalidate(companyChatRoomsListProvider);
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