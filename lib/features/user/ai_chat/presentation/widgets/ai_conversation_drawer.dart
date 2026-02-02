// ai_chat/presentation/widgets/ai_conversation_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/core/theme/app_theme.dart';
import '../providers/ai_chat_provider.dart';
import '../../domain/models/ai_conversation.dart';

class AiConversationDrawer extends ConsumerWidget {
  const AiConversationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(aiConversationsProvider);
    final selectedId = ref.watch(selectedConversationIdProvider);

    return Drawer(
      backgroundColor: ColorPalette.neutral900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(SpacePalette.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '会話履歴',
                    style: TextStylePalette.smHeader,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorPalette.neutral0,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: ColorPalette.neutral600, height: 1),

            // 新規会話ボタン
            Padding(
              padding: const EdgeInsets.all(SpacePalette.base),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final notifier = ref.read(aiConversationsProvider.notifier);
                    final newId = notifier.createConversation();
                    ref.read(selectedConversationIdProvider.notifier).state =
                        newId;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    foregroundColor: ColorPalette.neutral0,
                    padding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('新しい会話'),
                ),
              ),
            ),

            // 会話リスト
            Expanded(
              child: conversations.isEmpty
                  ? Center(
                      child: Text(
                        '会話履歴がありません',
                        style: TextStylePalette.subText,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.sm,
                      ),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final isSelected = conversation.id == selectedId;

                        return _ConversationTile(
                          conversation: conversation,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(selectedConversationIdProvider.notifier)
                                .state = conversation.id;
                            Navigator.of(context).pop();
                          },
                          onDelete: () {
                            ref
                                .read(aiConversationsProvider.notifier)
                                .deleteConversation(conversation.id);
                            if (selectedId == conversation.id) {
                              ref
                                  .read(selectedConversationIdProvider.notifier)
                                  .state = null;
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final AiConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.xs),
      decoration: BoxDecoration(
        color: isSelected ? ColorPalette.neutral600 : Colors.transparent,
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.sm,
          vertical: 0,
        ),
        leading: const Icon(
          Icons.chat_bubble_outline,
          color: ColorPalette.neutral400,
          size: 20,
        ),
        title: Text(
          conversation.title,
          style: TextStylePalette.normalText.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(conversation.updatedAt),
          style: TextStylePalette.subText.copyWith(fontSize: 11),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            color: ColorPalette.neutral400,
            size: 18,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
