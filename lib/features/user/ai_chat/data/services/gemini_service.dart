// ai_chat/data/services/gemini_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;

  static const _maxRetries = 3;
  static const _maxHistoryLength = 50;
  static const _systemPrompt =
      '''あなたは就活支援AIアシスタントです。
ユーザーの就職活動、インターンシップ、面接対策、自己PR、企業研究などの質問に対して、
親切で的確なアドバイスを日本語で提供してください。
回答は簡潔で分かりやすくしてください。''';

  GeminiService._() {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_AI_API_KEY is not set in .env file');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
  }

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  Future<String> _sendWithRetry(ChatSession chat, Content message) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await chat.sendMessage(message);
        return response.text ?? 'すみません、回答を生成できませんでした。';
      } catch (e) {
        final isRateLimit = e.toString().contains('Resource exhausted') ||
            e.toString().contains('429');
        if (isRateLimit && attempt < _maxRetries - 1) {
          final waitSeconds = (attempt + 1) * 3;
          debugPrint('Rate limited, retrying in ${waitSeconds}s (attempt ${attempt + 1})');
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('Resource exhausted') || msg.contains('429')) {
      return 'ただいまアクセスが集中しています。少し時間をおいてから再度お試しください。';
    }
    if (msg.contains('SocketException') || msg.contains('ClientException')) {
      return 'ネットワーク接続を確認してください。';
    }
    if (msg.contains('API key')) {
      return 'AI機能の設定に問題があります。管理者にお問い合わせください。';
    }
    return 'エラーが発生しました。しばらくしてからもう一度お試しください。';
  }

  Future<String> generateResponseWithContext(
    String userMessage,
    List<Map<String, String>> previousMessages,
  ) async {
    try {
      // 直近の履歴のみ使用してメモリを制限
      final recentMessages = previousMessages.length > _maxHistoryLength
          ? previousMessages.sublist(previousMessages.length - _maxHistoryLength)
          : previousMessages;
      final history = <Content>[];
      for (final msg in recentMessages) {
        if (msg['role'] == 'user') {
          history.add(Content.text(msg['content'] ?? ''));
        } else {
          history.add(Content.model([TextPart(msg['content'] ?? '')]));
        }
      }
      final chat = _model.startChat(history: history);
      return await _sendWithRetry(chat, Content.text(userMessage));
    } catch (e) {
      debugPrint('Gemini error: $e');
      return _formatError(e);
    }
  }
}
