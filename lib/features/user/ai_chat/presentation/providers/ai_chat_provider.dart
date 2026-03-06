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
final selectedConversationIdProvider = StateProvider<String?>((ref) => 'mock-1');

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
  AiConversationsNotifier() : super(_mockConversations);

  static final List<AiConversation> _mockConversations = [
    AiConversation(
      id: 'mock-1',
      title: '自己PRの書き方',
      messages: [
        AiMessage(id: 'm1-1', content: '自己PRの書き方を教えてください', isUser: true, createdAt: DateTime(2026, 3, 5, 10, 0)),
        AiMessage(id: 'm1-2', content: '自己PRを書く際のポイントは以下の通りです：\n\n1. **結論から書く** - 自分の強みを最初に明示しましょう\n2. **具体的なエピソード** - 強みを裏付ける経験を具体的に書きましょう\n3. **成果を数字で示す** - 「売上20%向上」など定量的な成果があると説得力が増します\n4. **企業への貢献** - その強みを入社後どう活かせるかを伝えましょう\n\n例文が必要でしたらお気軽にどうぞ！', isUser: false, createdAt: DateTime(2026, 3, 5, 10, 1)),
      ],
      createdAt: DateTime(2026, 3, 5, 10, 0),
      updatedAt: DateTime(2026, 3, 5, 10, 1),
    ),
    AiConversation(
      id: 'mock-2',
      title: '面接でよく聞かれる質問',
      messages: [
        AiMessage(id: 'm2-1', content: '面接でよく聞かれる質問を教えて', isUser: true, createdAt: DateTime(2026, 3, 4, 14, 0)),
        AiMessage(id: 'm2-2', content: '新卒面接でよく聞かれる質問TOP5をご紹介します：\n\n1. **自己紹介をお願いします** - 1分程度で簡潔に\n2. **志望動機を教えてください** - 企業研究が鍵\n3. **学生時代に力を入れたことは？** - ガクチカは必須\n4. **あなたの強み・弱みは？** - 弱みは改善姿勢もセットで\n5. **5年後のキャリアプランは？** - 成長意欲をアピール\n\nそれぞれの回答のコツも詳しく説明できますよ！', isUser: false, createdAt: DateTime(2026, 3, 4, 14, 1)),
        AiMessage(id: 'm2-3', content: 'ガクチカの具体的な書き方も知りたいです', isUser: true, createdAt: DateTime(2026, 3, 4, 14, 2)),
        AiMessage(id: 'm2-4', content: 'ガクチカ（学生時代に力を入れたこと）は**STAR法**で構成すると効果的です：\n\n- **S（状況）** - どんな場面だったか\n- **T（課題）** - 何が課題だったか\n- **A（行動）** - どう行動したか\n- **R（結果）** - どんな成果が出たか\n\n例：「サークルの新入生勧誘で参加者が減少していた（S）。目標の30人集客が課題だった（T）。SNS戦略を立案し週3回投稿を継続した（A）。結果、前年比150%の45人を集客できた（R）」', isUser: false, createdAt: DateTime(2026, 3, 4, 14, 3)),
      ],
      createdAt: DateTime(2026, 3, 4, 14, 0),
      updatedAt: DateTime(2026, 3, 4, 14, 3),
    ),
    AiConversation(
      id: 'mock-3',
      title: 'IT業界の企業研究',
      messages: [
        AiMessage(id: 'm3-1', content: 'IT業界で新卒に人気の企業を教えて', isUser: true, createdAt: DateTime(2026, 3, 3, 9, 0)),
        AiMessage(id: 'm3-2', content: 'IT業界で新卒に人気の企業カテゴリをご紹介します：\n\n**メガベンチャー**\n- サイバーエージェント、楽天、LINE、DeNA\n\n**SIer大手**\n- NTTデータ、富士通、NEC\n\n**外資系IT**\n- Google、Amazon、Microsoft\n\n**急成長スタートアップ**\n- SmartHR、LayerX、タイミー\n\nどの分野に興味がありますか？詳しく解説できます！', isUser: false, createdAt: DateTime(2026, 3, 3, 9, 1)),
      ],
      createdAt: DateTime(2026, 3, 3, 9, 0),
      updatedAt: DateTime(2026, 3, 3, 9, 1),
    ),
  ];

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
