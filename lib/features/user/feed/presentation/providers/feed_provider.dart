// feed/presentation/providers/feed_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabaseクライアントプロバイダー
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// フィード動画取得プロバイダー
final feedVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('company_videos')
        .select('*, companies(*)')
        .order('created_at', ascending: false)
        .limit(50);

    if (response == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    print('Error fetching feed videos: $e');
    rethrow;
  }
});

// 動画カテゴリ（タグ）一覧取得プロバイダー（使用頻度順で上位7件）
final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('company_videos')
        .select('tags')
        .eq('is_public', true);

    if (response == null) {
      return [];
    }

    // タグの出現回数をカウント
    final Map<String, int> tagCounts = {};
    for (final video in response as List) {
      final tags = video['tags'] as List<dynamic>?;
      if (tags != null) {
        for (final tag in tags) {
          if (tag != null && tag.toString().isNotEmpty) {
            final tagStr = tag.toString();
            tagCounts[tagStr] = (tagCounts[tagStr] ?? 0) + 1;
          }
        }
      }
    }

    // 出現回数順でソートして上位7件を取得
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(7).map((e) => e.key).toList();
  } catch (e) {
    print('Error fetching video categories: $e');
    return [];
  }
});

// 選択中のカテゴリ
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// カテゴリでフィルタリングした動画取得プロバイダー
final filteredVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  try {
    var query = supabase
        .from('company_videos')
        .select('*, companies(*)')
        .eq('is_public', true);

    if (selectedCategory != null) {
      query = query.contains('tags', [selectedCategory]);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(50);

    if (response == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    print('Error fetching filtered videos: $e');
    rethrow;
  }
});

// 特定の動画取得プロバイダー
final videoByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, videoId) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('company_videos')
        .select('*, companies(*)')
        .eq('id', videoId)
        .single();

    return response as Map<String, dynamic>;
  } catch (e) {
    print('Error fetching video by id: $e');
    return null;
  }
});