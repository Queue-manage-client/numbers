import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/chat/presentation/providers/chat_provider.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // TODO: 実際にはroute parameterからroomIdを取得
      const roomId = 'dummy-room-id';

      final repository = ref.read(chatRepositoryProvider);
      await repository.sendMessage(
        roomId: roomId,
        userId: user.id,
        content: _messageController.text.trim(),
      );

      _messageController.clear();
      ref.invalidate(messagesProvider(roomId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 実際にはroute parameterからroomIdを取得
    const roomId = 'dummy-room-id';
    final messagesAsync = ref.watch(messagesProvider(roomId));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('チャットルーム'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('メッセージがありません'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final profile =
                        message['profiles'] as Map<String, dynamic>?;
                    final isMe = ref.read(currentUserProvider)?.id ==
                        message['profile_id'];

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF323232)
                              : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['content'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF323232),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('エラー: $error')),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF323232),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
