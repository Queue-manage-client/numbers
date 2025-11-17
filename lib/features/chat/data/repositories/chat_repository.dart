import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    final response = await _supabase
        .from('chat_room_members')
        .select('room_id, chat_rooms(*)')
        .eq('profile_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final response = await _supabase
        .from('chat_messages')
        .select('*, profiles(*)')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'profile_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
