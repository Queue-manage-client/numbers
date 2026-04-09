// features/user/chat/presentation/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/chat/presentation/providers/chat_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/user/chat/presentation/pages/group_chat_create_page.dart';

class ChatListPage extends HookConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupChatsAsync = ref.watch(allGroupChatsProvider);
    final myChatRoomsAsync = ref.watch(chatRoomsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ColorPalette.neutral900,
        appBar: AppBar(
          title: const Text('チャット'),
          bottom: TabBar(
            indicatorColor: ColorPalette.primaryColor,
            labelColor: ColorPalette.primaryColor,
            unselectedLabelColor: ColorPalette.neutral500,
            dividerColor: ColorPalette.neutral600,
            dividerHeight: 0.5,
            tabs: const [
              Tab(text: 'グループ'),
              Tab(text: '企業DM'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // グループチャットタブ（全公開）
            _buildGroupChatTab(context, ref, allGroupChatsAsync),

            // DMタブ（参加中のみ）
            _buildDMTab(context, ref, myChatRoomsAsync),
          ],
        ),
      ),
    );
  }

  // グループチャットタブ
  Widget _buildGroupChatTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> groupChatsAsync,
  ) {
    return Stack(
      children: [
        _buildGroupChatContent(context, ref, groupChatsAsync),
        Positioned(
          right: SpacePalette.base,
          bottom: SpacePalette.base,
          child: FloatingActionButton(
            heroTag: 'createGroupChat',
            backgroundColor: ColorPalette.primaryColor,
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupChatCreatePage(),
                ),
              );
              if (result == true) {
                ref.invalidate(allGroupChatsProvider);
              }
            },
            child: const Icon(Icons.add, color: ColorPalette.neutral900),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupChatContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> groupChatsAsync,
  ) {
    return groupChatsAsync.when(
      data: (groupChats) {
        if (groupChats.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacePalette.base),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 80,
                    color: ColorPalette.neutral400,
                  ),
                  const SizedBox(height: SpacePalette.lg),
                  Text(
                    'グループチャットはありません',
                    style: TextStylePalette.header,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    'グループチャットが作成されると\nここに表示されます',
                    style: TextStylePalette.subText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(SpacePalette.base),
          itemCount: groupChats.length,
          itemBuilder: (context, index) {
            final room = groupChats[index];
            final roomName = room['name'] as String? ?? 'グループ';
            final description = room['description'] as String? ?? '';
            final roomId = room['id'] as String?;
            final iconUrl = room['icon_url'] as String?;
            final memberCountList = room['chat_room_members'] as List<dynamic>?;
            final members = (memberCountList != null && memberCountList.isNotEmpty)
                ? (memberCountList[0]['count'] as int? ?? 0)
                : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: SpacePalette.sm),
              child: InkWell(
                onTap: roomId != null
                    ? () => context.push('/chats/$roomId')
                    : null,
                borderRadius: BorderRadius.circular(RadiusPalette.lg),
                child: Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorPalette.neutral500,
                                width: 1.8,
                              ),
                            ),
                            child: buildChatIconWidget(iconUrl),
                          ),
                          const SizedBox(width: SpacePalette.base),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roomName,
                                  style: TextStylePalette.smListTitle,
                                ),
                                const SizedBox(height: SpacePalette.xs),
                                Text(
                                  '$members人が参加中',
                                  style: TextStylePalette.smListLeading,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        description,
                        style: TextStylePalette.subText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '参加する',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size12,
                              fontVariations: const [FontVariation('wght', 700)],
                              color: ColorPalette.primaryColor,
                            ),
                          ),
                          const SizedBox(width: SpacePalette.xs),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: ColorPalette.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
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
              const SizedBox(height: SpacePalette.lg),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(allGroupChatsProvider);
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
    );
  }

  // DMタブ
  Widget _buildDMTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> roomsAsync,
  ) {
    return roomsAsync.when(
      data: (rooms) {
        // DMのみをフィルタ（room_type == 'direct'）
        final dmRooms = rooms.where((roomData) {
          final room = roomData['chat_rooms'] as Map<String, dynamic>?;
          return room?['room_type'] == 'direct';
        }).toList();

        if (dmRooms.isEmpty) {
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
                    'DMはありません',
                    style: TextStylePalette.header,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    '求人に応募するとDMが開始されます',
                    style: TextStylePalette.subText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(SpacePalette.base),
          itemCount: dmRooms.length,
          itemBuilder: (context, index) {
            final roomData = dmRooms[index];
            final room = roomData['chat_rooms'] as Map<String, dynamic>?;

            if (room == null) return const SizedBox.shrink();

            final roomId = room['id'] as String;
            final roomName = room['name'] as String? ?? 'チャット';
            final company = room['companies'] as Map<String, dynamic>?;
            final logoUrl = company?['logo_url'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: SpacePalette.sm),
              child: ListTile(
                contentPadding: const EdgeInsets.all(SpacePalette.base),
                leading: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorPalette.neutral500,
                      width: 1.8,
                    ),
                  ),
                  child: (logoUrl != null && logoUrl.isNotEmpty)
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(logoUrl),
                          backgroundColor: ColorPalette.neutral600,
                        )
                      : CircleAvatar(
                          backgroundColor: ColorPalette.primaryColor,
                          child: Icon(
                            Icons.business,
                            color: ColorPalette.neutral0,
                          ),
                        ),
                ),
                title: Text(
                  roomName,
                  style: TextStylePalette.smListTitle,
                ),
                subtitle: Text(
                  '企業とのチャット',
                  style: TextStylePalette.smListLeading,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: ColorPalette.neutral500,
                ),
                onTap: () {
                  context.push('/chats/$roomId');
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
                  ref.invalidate(chatRoomsProvider);
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
    );
  }
}
