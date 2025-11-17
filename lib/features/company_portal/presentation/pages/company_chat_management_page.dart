import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyChatManagementPage extends StatelessWidget {
  const CompanyChatManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text('チャット管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/company-portal/chats/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規チャットルーム作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF323232),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/chats/list'),
                    icon: const Icon(Icons.list),
                    label: const Text('チャットルーム一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF323232),
                      side: const BorderSide(color: Color(0xFF323232)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'アクティブなチャットルーム',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
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
                      'アクティブなチャットルームはありません',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
