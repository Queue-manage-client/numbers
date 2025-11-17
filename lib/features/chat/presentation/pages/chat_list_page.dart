import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/chat/presentation/providers/chat_provider.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('チャット'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: chatRoomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('チャットがありません'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final chatRoom =
                  room['chat_rooms'] as Map<String, dynamic>?;

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF323232),
                  child: Icon(Icons.business, color: Color(0xFFFFFFFF)),
                ),
                title: Text(chatRoom?['room_type'] == 'direct'
                    ? 'ダイレクトメッセージ'
                    : 'グループチャット'),
                subtitle: const Text('最終メッセージ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/chats/${room['room_id']}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}
