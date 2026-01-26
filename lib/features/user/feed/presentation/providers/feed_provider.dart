// feed/presentation/providers/feed_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabaseクライアントプロバイダー
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// フィード動画取得プロバイダー（公開動画のみ）
final feedVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('company_videos')
        .select('*, companies(*)')
        .eq('is_public', true)
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
// 注: filteredVideosProviderと並列でデータを取得するため、
// feedVideosProviderのデータを再利用してクエリ数を削減
final videoCategoriesProvider = FutureProvider<List<String>>((ref) async {
  // feedVideosProviderのデータを再利用（追加クエリなし）
  final videosAsync = await ref.watch(feedVideosProvider.future);

  try {
    // タグの出現回数をカウント
    final Map<String, int> tagCounts = {};
    for (final video in videosAsync) {
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

// カテゴリでフィルタリングした動画プロバイダー（クライアント側フィルタ - DBクエリなし）
final filteredVideosProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final videosAsync = ref.watch(feedVideosProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return videosAsync.when(
    data: (videos) {
      if (selectedCategory == null) {
        return AsyncValue.data(videos);
      }
      // クライアント側でフィルタリング（DBクエリなし）
      final filtered = videos.where((video) {
        final tags = video['tags'] as List<dynamic>?;
        if (tags == null) return false;
        return tags.contains(selectedCategory);
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
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