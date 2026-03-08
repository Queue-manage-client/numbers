// features/user/chat/data/repositories/chat_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  /// ユーザーが参加しているチャットルーム一覧を取得
  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    try {
      final response = await _supabase
          .from('chat_room_members')
          .select('room_id, chat_rooms(*)')
          .eq('profile_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting chat rooms: $e');
      return [];
    }
  }

  /// すべてのグループチャットを取得（全公開）
  Future<List<Map<String, dynamic>>> getAllGroupChats() async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select('*, companies(*), chat_room_members(count)')
          .eq('room_type', 'group')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting all group chats: $e');
      return [];
    }
  }

  /// チャットルームのメッセージ一覧を取得
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*, profiles(*)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  /// メッセージを送信
  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'profile_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // チャットルームの最終更新日時を更新（updated_atがある場合のみ）
      try {
        await _supabase.from('chat_rooms').update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId);
      } catch (e) {
        // updated_atカラムがない場合は無視
        debugPrint('Note: updated_at column not found (this is OK): $e');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
}