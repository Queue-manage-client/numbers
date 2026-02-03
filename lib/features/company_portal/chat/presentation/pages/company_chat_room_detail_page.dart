// features/company_portal/chat/presentation/pages/company_chat_room_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:numbers/features/company_portal/chat/presentation/providers/company_chat_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class CompanyChatRoomDetailPage extends HookConsumerWidget {
  final String roomId;

  const CompanyChatRoomDetailPage({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isSending = useState(false);

    final roomAsync = ref.watch(chatRoomByIdProvider(roomId));
    final messagesAsync = ref.watch(chatMessagesProvider(roomId));
    final currentUser = ref.watch(currentUserProvider);

    final sendMessage = useCallback(() async {
      if (messageController.text.trim().isEmpty) return;
      if (currentUser == null) return;

      isSending.value = true;

      try {
        await ref.read(companyChatRepositoryProvider).sendMessage(
              roomId: roomId,
              userId: currentUser.id,
              content: messageController.text.trim(),
            );

        messageController.clear();
        ref.invalidate(chatMessagesProvider(roomId));

        // スクロールを一番下へ
        if (scrollController.hasClients) {
          await Future.delayed(const Duration(milliseconds: 100));
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '送信エラー: $e',
                style: TextStylePalette.normalText.copyWith(
                  color: ColorPalette.neutral0,
                ),
              ),
              backgroundColor: ColorPalette.primaryColor,
            ),
          );
        }
      } finally {
        isSending.value = false;
      }
    }, [messageController, currentUser, roomId]);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorPalette.neutral0,
          ),
          onPressed: () => context.go('/company-portal/chats/list'),
        ),
        title: roomAsync.when(
          data: (room) => Text(room?['name'] ?? 'チャットルーム'),
          loading: () => const Text('チャットルーム'),
          error: (_, __) => const Text('チャットルーム'),
        ),
      ),
      body: Column(
        children: [
          // メッセージリスト
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: ColorPalette.neutral400,
                        ),
                        const SizedBox(height: SpacePalette.lg),
                        Text(
                          'メッセージはありません',
                          style: TextStylePalette.header,
                        ),
                        const SizedBox(height: SpacePalette.sm),
                        Text(
                          '最初のメッセージを送信しましょう',
                          style: TextStylePalette.subText,
                        ),
                      ],
                    ),
                  );
                }

                // メッセージ送信後に自動スクロール
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final profile = message['profiles'] as Map<String, dynamic>?;
                    final isMe = currentUser?.id == message['profile_id'];
                    final senderName = profile?['display_name'] ?? '不明なユーザー';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacePalette.inner,
                          vertical: SpacePalette.sm,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? ColorPalette.primaryColor
                              : ColorPalette.neutral0,
                          borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: TextStylePalette.smSubTitle,
                              ),
                              const SizedBox(height: SpacePalette.xs),
                            ],
                            Text(
                              message['content'] ?? '',
                              style: TextStylePalette.normalText.copyWith(
                                color: isMe
                                    ? ColorPalette.neutral0
                                    : ColorPalette.neutral800,
                              ),
                            ),
                            const SizedBox(height: SpacePalette.xs),
                            Text(
                              _formatTime(message['created_at']),
                              style: TextStylePalette.smSubText.copyWith(
                                color: isMe
                                    ? ColorPalette.neutral0.withOpacity(0.7)
                                    : ColorPalette.neutral500,
                              ),
                            ),
                          ],
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

          // メッセージ入力フォーム
          Container(
            padding: const EdgeInsets.all(SpacePalette.base),
            decoration: BoxDecoration(
              color: ColorPalette.neutral0,
              border: Border(
                top: BorderSide(color: ColorPalette.neutral200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      hintStyle: TextStylePalette.hintText,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                        vertical: SpacePalette.inner,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Container(
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isSending.value ? null : sendMessage,
                    icon: isSending.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.neutral0,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: ColorPalette.neutral0,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return '昨日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}