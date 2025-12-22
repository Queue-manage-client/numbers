// features/company_portal/chat/presentation/pages/company_chat_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyChatManagementPage extends StatelessWidget {
  const CompanyChatManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral100,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorPalette.neutral800,
          ),
          onPressed: () => context.go('/company-portal/dashboard'),
        ),
        title: const Text('チャット管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpacePalette.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/company-portal/chats/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規作成'),
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/company-portal/chats/list'),
                    icon: Icon(
                      Icons.list,
                      color: ColorPalette.primaryColor,
                    ),
                    label: const Text('一覧'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColor,
                      side: const BorderSide(
                        color: ColorPalette.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacePalette.lg * 2),
            Text(
              'アクティブなチャットルーム',
              style: TextStylePalette.smHeader,
            ),
            const SizedBox(height: SpacePalette.base),
            Expanded(
              child: Center(
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
                      'アクティブなチャットルームはありません',
                      style: TextStylePalette.header,
                    ),
                    const SizedBox(height: SpacePalette.sm),
                    Text(
                      '学生とのコミュニケーションを始めましょう',
                      style: TextStylePalette.subText,
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
            ),
          ],
        ),
      ),
    );
  }
}