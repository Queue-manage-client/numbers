// ai_chat/data/services/gemini_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;
  final List<Content> _conversationHistory = [];

  GeminiService._() {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_AI_API_KEY is not set in .env file');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: apiKey,
      systemInstruction: Content.text(
        '''あなたは就活支援AIアシスタントです。
ユーザーの就職活動、インターンシップ、面接対策、自己PR、企業研究などの質問に対して、
親切で的確なアドバイスを日本語で提供してください。
回答は簡潔で分かりやすくしてください。''',
      ),
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

  void clearHistory() {
    _conversationHistory.clear();
  }

  Future<String> generateResponse(String userMessage) async {
    try {
      // Add user message to history
      _conversationHistory.add(Content.text(userMessage));

      // Start chat with history
      final chat = _model.startChat(history: _conversationHistory);

      // Generate response
      final response = await chat.sendMessage(Content.text(userMessage));
      final responseText = response.text ?? 'すみません、回答を生成できませんでした。';

      // Add AI response to history
      _conversationHistory.add(Content.model([TextPart(responseText)]));

      return responseText;
    } catch (e) {
      return 'エラーが発生しました: ${e.toString()}';
    }
  }

  Future<String> generateResponseWithContext(
    String userMessage,
    List<Map<String, String>> previousMessages,
  ) async {
    try {
      // Build conversation history from previous messages
      final history = <Content>[];
      for (final msg in previousMessages) {
        if (msg['role'] == 'user') {
          history.add(Content.text(msg['content'] ?? ''));
        } else {
          history.add(Content.model([TextPart(msg['content'] ?? '')]));
        }
      }

      // Start chat with history
      final chat = _model.startChat(history: history);

      // Generate response
      final response = await chat.sendMessage(Content.text(userMessage));
      final responseText = response.text ?? 'すみません、回答を生成できませんでした。';

      return responseText;
    } catch (e) {
      return 'エラーが発生しました: ${e.toString()}';
    }
  }
}
