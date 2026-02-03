// ai_chat/presentation/providers/ai_chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/gemini_service.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';

const _uuid = Uuid();

// Gemini service provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService.instance;
});

// 会話一覧を管理するプロバイダー
final aiConversationsProvider =
    StateNotifierProvider<AiConversationsNotifier, List<AiConversation>>((ref) {
  return AiConversationsNotifier();
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
  AiConversationsNotifier() : super([]);

  // 新しい会話を作成
  String createConversation() {
    final id = _uuid.v4();
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
  void deleteConversation(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  // メッセージを追加
  void addMessage(String conversationId, AiMessage message) {
    state = state.map((c) {
      if (c.id == conversationId) {
        final newMessages = [...c.messages, message];
        // 最初のユーザーメッセージをタイトルにする
        String title = c.title;
        if (message.isUser && c.messages.isEmpty) {
          title = message.content.length > 20
              ? '${message.content.substring(0, 20)}...'
              : message.content;
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
    addMessage(conversationId, userMsg);

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
      addMessage(conversationId, aiMsg);
    } catch (e) {
      // エラー時のフォールバック応答
      final aiMsg = AiMessage(
        id: _uuid.v4(),
        content: 'すみません、エラーが発生しました。しばらくしてからもう一度お試しください。',
        isUser: false,
        createdAt: DateTime.now(),
      );
      addMessage(conversationId, aiMsg);
    }
  }
}
