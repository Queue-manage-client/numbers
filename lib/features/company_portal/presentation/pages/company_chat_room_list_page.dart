import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyChatRoomListPage extends StatelessWidget {
  const CompanyChatRoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: データベースからチャットルームリストを取得
    final chatRooms = <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('チャットルーム一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/company-portal/chats/create'),
          ),
        ],
      ),
      body: chatRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'チャットルームはありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/company-portal/chats/create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: const Text('最初のチャットルームを作成'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                final isGroup = room['type'] == 'group';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFF323232),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF323232),
                      child: Icon(
                        isGroup ? Icons.group : Icons.person,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                    title: Text(
                      room['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF323232),
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isGroup ? 'グループチャット' : 'ダイレクトメッセージ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (room['lastMessage'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            room['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF323232),
                    ),
                    onTap: () {
                      context.go('/company-portal/chats/${room['id']}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
