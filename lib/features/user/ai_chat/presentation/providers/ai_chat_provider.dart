// ai_chat/presentation/providers/ai_chat_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../data/services/gemini_service.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';

const _uuid = Uuid();

// Supabaseクライアントプロバイダー
final _supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// AI Chatリポジトリプロバイダー
final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository(ref.watch(_supabaseProvider));
});

// Gemini service provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService.instance;
});

// 会話一覧を管理するプロバイダー
final aiConversationsProvider =
    StateNotifierProvider<AiConversationsNotifier, List<AiConversation>>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return AiConversationsNotifier(repository);
});

// 現在選択中の会話IDを管理するプロバイダー
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

// 現在の会話を取得するプロバイダー
final currentConversationProvider = Provider<AiConversation?>((ref) {
  final conversations = ref.watch(aiConversationsProvider);
  final selectedId = ref.watch(selectedConversationIdProvider);

  if (selectedId == null) return null;

  try {
    return conversations.firstWhere((c) => c.id == selectedId);
  } catch (_) {
    return null;
  }
});

class AiConversationsNotifier extends StateNotifier<List<AiConversation>> {
  final AiChatRepository _repository;
  bool _isLoaded = false;

  AiConversationsNotifier(this._repository) : super([]);

  /// DBから会話を読み込み
  Future<void> loadConversations() async {
    if (_isLoaded) return;
    final conversations = await _repository.getConversations();
    state = conversations;
    _isLoaded = true;
  }

  // 新しい会話を作成
  Future<String?> createConversation() async {
    final id = await _repository.createConversation();
    if (id == null) return null;

    final now = DateTime.now();
    final conversation = AiConversation(
      id: id,
      title: '新しい会話',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );

    state = [conversation, ...state];
    return id;
  }

  // 会話を削除
  Future<void> deleteConversation(String id) async {
    await _repository.deleteConversation(id);
    state = state.where((c) => c.id != id).toList();
  }

  // メッセージを追加（ローカル + DB）
  Future<void> _addMessage(String conversationId, AiMessage message) async {
    // DBに保存
    final savedId = await _repository.addMessage(
      conversationId: conversationId,
      content: message.content,
      isUser: message.isUser,
    );

    final actualMessage = savedId != null
        ? AiMessage(id: savedId, content: message.content, isUser: message.isUser, createdAt: message.createdAt)
        : message;

    // ローカルステートを更新
    state = state.map((c) {
      if (c.id == conversationId) {
        final newMessages = [...c.messages, actualMessage];
        String title = c.title;
        if (message.isUser && c.messages.isEmpty) {
          title = message.content.length > 20
              ? '${message.content.substring(0, 20)}...'
              : message.content;
          // タイトルもDB更新
          _repository.updateConversationTitle(conversationId, title);
        }
        return c.copyWith(
          messages: newMessages,
          title: title,
          updatedAt: DateTime.now(),
        );
      }
      return c;
    }).toList();
  }

  // AI応答を生成（Gemini API）
  Future<void> generateAiResponse(String conversationId, String userMessage) async {
    // ユーザーメッセージを追加
    final userMsg = AiMessage(
      id: _uuid.v4(),
      content: userMessage,
      isUser: true,
      createdAt: DateTime.now(),
    );
    await _addMessage(conversationId, userMsg);

    try {
      // 会話履歴を取得
      final conversation = state.firstWhere((c) => c.id == conversationId);
      final previousMessages = conversation.messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      // Gemini APIで応答を生成
      final geminiService = GeminiService.instance;
      final response = await geminiService.generateResponseWithContext(
        userMessage,
        previousMessages,
      );

      // AI応答を追加
      final aiMsg = AiMessage(
        id: _uuid.v4(),
        content: response,
        isUser: false,
        createdAt: DateTime.now(),
      );
      await _addMessage(conversationId, aiMsg);
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      // エラー時のフォールバック応答
      final aiMsg = AiMessage(
        id: _uuid.v4(),
        content: 'すみません、エラーが発生しました。しばらくしてからもう一度お試しください。',
        isUser: false,
        createdAt: DateTime.now(),
      );
      await _addMessage(conversationId, aiMsg);
    }
  }
}
