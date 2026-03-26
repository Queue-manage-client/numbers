// features/user/chat/presentation/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/chat/data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatRepository(supabase);
});

// ユーザーが参加しているチャットルーム一覧
final chatRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getChatRooms(user.id);
});

// すべてのグループチャット（全公開）
final allGroupChatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getAllGroupChats();
});

// メッセージ一覧（リアルタイムストリーム）
final messagesStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
    (ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.messagesStream(roomId);
});

// レガシー互換: FutureProviderも残す（他から参照されている場合）
final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, roomId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.getMessages(roomId);
});

// 未読メッセージ数を取得するプロバイダー
final unreadCountProvider = FutureProvider.family<int, String>((ref, roomId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  final supabase = ref.watch(supabaseClientProvider);

  // メンバーのlast_read_atを取得
  final memberData = await supabase
      .from('chat_room_members')
      .select('last_read_at')
      .eq('room_id', roomId)
      .eq('profile_id', user.id)
      .maybeSingle();

  final lastReadAt = memberData?['last_read_at'] as String?;

  if (lastReadAt == null) {
    // 一度も既読をつけていない場合は全メッセージが未読
    final response = await supabase
        .from('chat_messages')
        .select('id')
        .eq('room_id', roomId)
        .neq('profile_id', user.id);
    return (response as List).length;
  }

  // last_read_at以降のメッセージ数をカウント
  final response = await supabase
      .from('chat_messages')
      .select('id')
      .eq('room_id', roomId)
      .neq('profile_id', user.id)
      .gt('created_at', lastReadAt);
  return (response as List).length;
});
