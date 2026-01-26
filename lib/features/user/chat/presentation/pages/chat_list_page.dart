// features/user/chat/presentation/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/chat/presentation/providers/chat_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ChatListPage extends HookConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupChatsAsync = ref.watch(allGroupChatsProvider);
    final myChatRoomsAsync = ref.watch(chatRoomsProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ColorPalette.neutral100,
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
              Tab(text: 'DM'),
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
        bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      ),
    );
  }

  // グループチャットタブ
  Widget _buildGroupChatTab(
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
                    Icons.group_outlined,
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
                    '企業が作成するのをお待ちください',
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
            final roomId = room['id'] as String;
            final roomName = room['name'] as String? ?? 'グループチャット';
            final description = room['description'] as String? ?? '';
            final company = room['companies'] as Map<String, dynamic>?;
            final companyName = company?['name'] as String? ?? '企業';

            return Card(
              margin: const EdgeInsets.only(bottom: SpacePalette.sm),
              child: InkWell(
                onTap: () {
                  context.push('/chats/$roomId');
                },
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
                            child: CircleAvatar(
                              backgroundColor: ColorPalette.primaryColor,
                              child: Icon(
                                Icons.group,
                                color: ColorPalette.neutral0,
                              ),
                            ),
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
                                  companyName,
                                  style: TextStylePalette.smListLeading,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.sm),
                        Text(
                          description,
                          style: TextStylePalette.subText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: SpacePalette.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/chats/$roomId');
                          },
                          icon: const Icon(Icons.login, size: 18, color: ColorPalette.neutral0),
                          label: Text('参加する', style: TextStylePalette.buttonTextBlack),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: ColorPalette.neutral0,
                            padding: const EdgeInsets.symmetric(
                              vertical: SpacePalette.inner,
                            ),
                          ),
                        ),
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
              const SizedBox(height: SpacePalette.sm),
              Text(
                '$error',
                style: TextStylePalette.subText,
                textAlign: TextAlign.center,
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
                  child: CircleAvatar(
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