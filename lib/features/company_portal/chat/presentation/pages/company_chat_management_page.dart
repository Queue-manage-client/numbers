// features/company_portal/chat/presentation/pages/company_chat_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

import 'package:numbers/features/company_portal/chat/presentation/providers/company_chat_provider.dart';
import 'package:numbers/features/company_portal/intern/presentation/providers/company_intern_provider.dart';
import 'package:numbers/features/user/intern/domain/models/internship.dart';

class CompanyChatManagementPage extends ConsumerWidget {
  final bool inShell;

  const CompanyChatManagementPage({super.key, this.inShell = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(companyChatRoomsListProvider);
    final internshipsAsync = ref.watch(companyInternshipsProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: inShell
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: ColorPalette.neutral0,
                ),
                onPressed: () => context.go('/feed'),
              ),
        title: const Text('チャット管理'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(companyChatRoomsListProvider);
          ref.invalidate(companyInternshipsProvider);
        },
        color: ColorPalette.primaryColor,
        backgroundColor: ColorPalette.neutral800,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Create new chat room button
              ElevatedButton.icon(
                onPressed: () => context.go('/company-portal/chats/create'),
                icon: const Icon(Icons.add),
                label: const Text('新規チャットルーム作成'),
              ),
              const SizedBox(height: SpacePalette.lg * 2),

              // Active Chat Rooms Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'アクティブなチャットルーム',
                    style: TextStylePalette.smHeader,
                  ),
                  chatRoomsAsync.maybeWhen(
                    data: (rooms) => Text(
                      '${rooms.length}件',
                      style: TextStylePalette.subText,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: SpacePalette.base),
              _buildChatRoomsList(context, ref, chatRoomsAsync),

              const SizedBox(height: SpacePalette.lg * 2),

              // Internships Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'インターン',
                    style: TextStylePalette.smHeader,
                  ),
                  internshipsAsync.maybeWhen(
                    data: (interns) => Text(
                      '${interns.length}件',
                      style: TextStylePalette.subText,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: SpacePalette.base),
              _buildInternshipsList(context, ref, internshipsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> chatRoomsAsync,
  ) {
    return chatRoomsAsync.when(
      data: (chatRooms) {
        if (chatRooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'チャットルームはありません',
            subtitle: '最初のチャットルームを作成しましょう',
            buttonLabel: '最初のチャットルームを作成',
            onPressed: () => context.go('/company-portal/chats/create'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final room = chatRooms[index];
            return _ChatRoomCard(room: room);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(SpacePalette.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _buildErrorState(
        error: error,
        onRetry: () => ref.invalidate(companyChatRoomsListProvider),
      ),
    );
  }

  Widget _buildInternshipsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Internship>> internshipsAsync,
  ) {
    return internshipsAsync.when(
      data: (interns) {
        if (interns.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'インターンはありません',
            subtitle: '最初のインターンを投稿しましょう',
            buttonLabel: '最初のインターンを投稿',
            onPressed: () => context.go('/company-portal/interns/post'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: interns.length,
          itemBuilder: (context, index) {
            final intern = interns[index];
            return _InternshipCard(intern: intern);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(SpacePalette.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _buildErrorState(
        error: error,
        onRetry: () => ref.invalidate(companyInternshipsProvider),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(SpacePalette.lg),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: ColorPalette.neutral400,
          ),
          const SizedBox(height: SpacePalette.base),
          Text(
            title,
            style: TextStylePalette.smTitle,
          ),
          const SizedBox(height: SpacePalette.xs),
          Text(
            subtitle,
            style: TextStylePalette.subText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacePalette.base),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required Object error,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(SpacePalette.lg),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: ColorPalette.primaryColor,
          ),
          const SizedBox(height: SpacePalette.base),
          Text(
            'エラーが発生しました',
            style: TextStylePalette.smTitle,
          ),
          const SizedBox(height: SpacePalette.xs),
          Text(
            '$error',
            style: TextStylePalette.subText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacePalette.base),
          OutlinedButton(
            onPressed: onRetry,
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
    );
  }
}

class _ChatRoomCard extends ConsumerWidget {
  final Map<String, dynamic> room;

  const _ChatRoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = room['room_type'] == 'group';
    final members = room['chat_room_members'] as List?;
    final memberCount = members?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      color: ColorPalette.neutral800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        side: BorderSide(color: ColorPalette.neutral600),
      ),
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
          room['name'] ?? 'チャットルーム',
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
          color: ColorPalette.neutral800,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(
                    Icons.chat,
                    size: 20,
                    color: ColorPalette.neutral0,
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
                  backgroundColor: ColorPalette.neutral800,
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
  }
}

class _InternshipCard extends ConsumerWidget {
  final Internship intern;

  const _InternshipCard({required this.intern});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(applicationCountsProvider(intern.id));

    return Card(
      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
      color: ColorPalette.neutral800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        side: BorderSide(color: ColorPalette.neutral600),
      ),
      child: InkWell(
        onTap: () => context.go('/company-portal/interns/${intern.id}/applications'),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ColorPalette.primaryColor,
                    radius: 20,
                    child: Icon(
                      Icons.school,
                      color: ColorPalette.neutral0,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: SpacePalette.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(intern.title, style: TextStylePalette.smTitle),
                        const SizedBox(height: SpacePalette.xs),
                        Row(
                          children: [
                            Icon(
                              intern.isPublic ? Icons.public : Icons.public_off,
                              size: 14,
                              color: intern.isPublic ? Colors.green : ColorPalette.neutral400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              intern.isPublic ? '公開中' : '非公開',
                              style: TextStylePalette.smText.copyWith(
                                color: intern.isPublic ? Colors.green : ColorPalette.neutral400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ColorPalette.neutral500,
                  ),
                ],
              ),
              const SizedBox(height: SpacePalette.sm),
              // Application counts
              countsAsync.when(
                data: (counts) => Row(
                  children: [
                    _buildCountChip('申込', counts['total'] ?? 0, ColorPalette.primaryColor),
                    const SizedBox(width: SpacePalette.sm),
                    _buildCountChip('審査中', counts['pending'] ?? 0, Colors.orange),
                    const SizedBox(width: SpacePalette.sm),
                    _buildCountChip('承認', counts['approved'] ?? 0, Colors.green),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RadiusPalette.mini),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: FontSizePalette.size12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
