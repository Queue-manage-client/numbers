// ai_chat/data/services/gemini_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;

  // フォールバック値（DB取得失敗時）
  static const _fallbackModel = 'gemini-2.5-flash';
  static const _fallbackTemperature = 0.7;
  static const _fallbackMaxTokens = 1024;
  static const _fallbackMaxRetries = 3;
  static const _fallbackMaxHistory = 50;
  static const _fallbackPrompt =
      '''あなたは就活支援AIアシスタントです。
ユーザーの就職活動、インターンシップ、面接対策、自己PR、企業研究などの質問に対して、
親切で的確なアドバイスを日本語で提供してください。
回答は簡潔で分かりやすくしてください。''';

  int _maxRetries = _fallbackMaxRetries;
  int _maxHistoryLength = _fallbackMaxHistory;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// ai_configテーブルから設定を読み込みモデルを初期化
  Future<void> _ensureInitialized() async {
    if (_model != null) return;

    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_AI_API_KEY is not set in .env file');
    }

    // DBから設定を取得（失敗時はフォールバック値を使用）
    String modelName = _fallbackModel;
    String systemPrompt = _fallbackPrompt;
    double temperature = _fallbackTemperature;
    int maxTokens = _fallbackMaxTokens;

    try {
      final response = await Supabase.instance.client
          .from('ai_config')
          .select()
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        modelName = response['model_name'] as String? ?? _fallbackModel;
        systemPrompt = response['system_prompt'] as String? ?? _fallbackPrompt;
        temperature = (response['temperature'] as num?)?.toDouble() ?? _fallbackTemperature;
        maxTokens = response['max_output_tokens'] as int? ?? _fallbackMaxTokens;
        _maxRetries = response['max_retries'] as int? ?? _fallbackMaxRetries;
        _maxHistoryLength = response['max_history_length'] as int? ?? _fallbackMaxHistory;
      }
    } catch (e) {
      debugPrint('Failed to load ai_config, using fallback: $e');
    }

    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.text(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxTokens,
      ),
    );
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
      await _ensureInitialized();

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
      final chat = _model!.startChat(history: history);
      return await _sendWithRetry(chat, Content.text(userMessage));
    } catch (e) {
      debugPrint('Gemini error: $e');
      return _formatError(e);
    }
  }
}
