// features/user/chat/presentation/pages/chat_room_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/chat/presentation/providers/chat_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

import 'package:numbers/core/theme/app_theme.dart';

class ChatRoomPage extends HookConsumerWidget {
  final String roomId;

  const ChatRoomPage({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isSending = useState(false);

    final messagesAsync = ref.watch(messagesStreamProvider(roomId));
    final prevMessageCount = useRef(0);
    final currentUser = ref.watch(currentUserProvider);
    final sendMessage = useCallback(() async {
      if (messageController.text.trim().isEmpty) return;
      if (currentUser == null) return;

      isSending.value = true;

      try {
        await ref.read(chatRepositoryProvider).sendMessage(
              roomId: roomId,
              userId: currentUser.id,
              content: messageController.text.trim(),
            );

        messageController.clear();

        // スクロールを一番下へ（Streamが自動更新するので少し待つ）
        if (scrollController.hasClients) {
          await Future.delayed(const Duration(milliseconds: 200));
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
                'メッセージの送信に失敗しました',
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/chats');
            }
          },
        ),
        title: const Text('チャット'),
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

                // 新着メッセージ到着時のみ自動スクロール
                if (messages.length != prevMessageCount.value) {
                  prevMessageCount.value = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (scrollController.hasClients) {
                      scrollController.jumpTo(
                        scrollController.position.maxScrollExtent,
                      );
                    }
                  });
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final profile = message['profiles'] as Map<String, dynamic>?;
                    final isMe = currentUser?.id == message['profile_id'];
                    final senderName = profile?['display_name'] ?? 
                                      profile?['email'] ?? 
                                      '不明なユーザー';

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
                              : ColorPalette.neutral800,
                          borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: TextStylePalette.smSubTitle.copyWith(
                                  color: ColorPalette.neutral300,
                                ),
                              ),
                              const SizedBox(height: SpacePalette.xs),
                            ],
                            Text(
                              message['content'] ?? '',
                              style: TextStylePalette.normalText.copyWith(
                                color: ColorPalette.neutral0,
                              ),
                            ),
                            const SizedBox(height: SpacePalette.xs),
                            Text(
                              _formatTime(message['created_at']),
                              style: TextStylePalette.smSubText.copyWith(
                                color: ColorPalette.neutral400,
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
                      'メッセージの読み込みに失敗しました',
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
              color: ColorPalette.neutral800,
              border: Border(
                top: BorderSide(color: ColorPalette.neutral600),
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
                      filled: true,
                      fillColor: ColorPalette.neutral800,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                        vertical: SpacePalette.inner,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        borderSide: BorderSide(color: ColorPalette.primaryColor),
                      ),
                    ),
                    maxLines: null,
                    maxLength: 2000,
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
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      if (messageDate == today) {
        return timeStr;
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return '昨日 $timeStr';
      } else {
        return '${dateTime.month}/${dateTime.day} $timeStr';
      }
    } catch (e) {
      return '';
    }
  }
}