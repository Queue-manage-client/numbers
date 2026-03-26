// ai_chat/data/services/gemini_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static GeminiService? _instance;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// Edge Function経由でGemini APIを呼び出す
  Future<String> generateResponseWithContext(
    String userMessage,
    List<Map<String, String>> previousMessages,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {
          'message': userMessage,
          'history': previousMessages,
        },
      );

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        final errorMsg = data?['error'] as String?;
        return errorMsg ?? 'エラーが発生しました。しばらくしてからもう一度お試しください。';
      }

      final data = response.data as Map<String, dynamic>;
      return data['response'] as String? ?? 'すみません、回答を生成できませんでした。';
    } catch (e) {
      debugPrint('Gemini Edge Function error: $e');
      return _formatError(e);
    }
  }

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('ClientException')) {
      return 'ネットワーク接続を確認してください。';
    }
    return 'エラーが発生しました。しばらくしてからもう一度お試しください。';
  }
}
