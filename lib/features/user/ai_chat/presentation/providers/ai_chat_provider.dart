// ai_chat/presentation/providers/ai_chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';

const _uuid = Uuid();

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

  // AI応答を生成（サンプル）
  Future<void> generateAiResponse(String conversationId, String userMessage) async {
    // ユーザーメッセージを追加
    final userMsg = AiMessage(
      id: _uuid.v4(),
      content: userMessage,
      isUser: true,
      createdAt: DateTime.now(),
    );
    addMessage(conversationId, userMsg);

    // 模擬遅延
    await Future.delayed(const Duration(milliseconds: 500));

    // サンプル応答を生成
    String response;
    if (userMessage.contains('就活') || userMessage.contains('就職')) {
      response = '就活についてのご質問ですね。就職活動では自己分析、企業研究、面接対策が重要です。何か具体的にお聞きになりたいことはありますか？';
    } else if (userMessage.contains('インターン')) {
      response = 'インターンシップは実際の業務を経験できる貴重な機会です。気になる企業があれば、インターンページから探してみてください。';
    } else if (userMessage.contains('面接')) {
      response = '面接では、自己PRや志望動機をしっかり準備することが大切です。また、企業研究を行い、質問に具体的に答えられるようにしましょう。';
    } else {
      response = 'ご質問ありがとうございます。就活に関することなら何でもお気軽にお聞きください。実装時にAI APIと連携してより詳しい回答ができるようになります。';
    }

    // AI応答を追加
    final aiMsg = AiMessage(
      id: _uuid.v4(),
      content: response,
      isUser: false,
      createdAt: DateTime.now(),
    );
    addMessage(conversationId, aiMsg);
  }
}
