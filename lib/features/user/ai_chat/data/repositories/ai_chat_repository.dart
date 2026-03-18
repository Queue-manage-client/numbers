// ai_chat/data/repositories/ai_chat_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';

class AiChatRepository {
  final SupabaseClient _supabase;

  AiChatRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// 会話一覧を取得（メッセージ含む）
  Future<List<AiConversation>> getConversations() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('ai_conversations')
          .select('*, ai_conversation_messages(*)')
          .eq('profile_id', userId)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((conv) {
        final messages = (conv['ai_conversation_messages'] as List<dynamic>? ?? [])
            .map((m) => AiMessage(
                  id: m['id'] as String,
                  content: m['content'] as String,
                  isUser: m['is_user'] as bool,
                  createdAt: DateTime.parse(m['created_at'] as String),
                ))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return AiConversation(
          id: conv['id'] as String,
          title: conv['title'] as String? ?? '新しい会話',
          messages: messages,
          createdAt: DateTime.parse(conv['created_at'] as String),
          updatedAt: DateTime.parse(conv['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 新しい会話を作成
  Future<String?> createConversation({String title = '新しい会話'}) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('ai_conversations')
          .insert({
            'profile_id': userId,
            'title': title,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// 会話を削除
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('ai_conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      rethrow;
    }
  }

  /// 会話タイトルを更新
  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      await _supabase.from('ai_conversations').update({
        'title': title,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
    } catch (e) {
      rethrow;
    }
  }

  /// メッセージを追加
  Future<String?> addMessage({
    required String conversationId,
    required String content,
    required bool isUser,
  }) async {
    try {
      final response = await _supabase
          .from('ai_conversation_messages')
          .insert({
            'conversation_id': conversationId,
            'content': content,
            'is_user': isUser,
          })
          .select()
          .single();

      // 会話のupdated_atを更新
      await _supabase.from('ai_conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return response['id'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
