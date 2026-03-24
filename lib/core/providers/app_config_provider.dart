// core/providers/app_config_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

/// app_configテーブルからキーに対応する値を取得
final appConfigProvider =
    FutureProvider.family<dynamic, String>((ref, key) async {
  try {
    final response = await _supabase
        .from('app_config')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    return response?['value'];
  } catch (e) {
    debugPrint('Error fetching app_config[$key]: $e');
    return null;
  }
});

/// legal_documentsテーブルから法的文書を取得
final legalDocumentProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, docType) async {
  try {
    final response = await _supabase
        .from('legal_documents')
        .select()
        .eq('doc_type', docType)
        .eq('is_active', true)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  } catch (e) {
    debugPrint('Error fetching legal_document[$docType]: $e');
    return null;
  }
});

/// ai_configテーブルからアクティブな設定を取得
final aiConfigProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await _supabase
        .from('ai_config')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    return response;
  } catch (e) {
    debugPrint('Error fetching ai_config: $e');
    return null;
  }
});
