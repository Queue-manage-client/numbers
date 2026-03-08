// feed/presentation/providers/feed_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 業種フォールバックリスト（DBから取得できない場合に使用）
const List<String> defaultIndustries = [
  'IT', '金融', '建築・土木', '製造', 'サービス', '小売', '医療・福祉', '教育',
];

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

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching feed videos: $e');
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
    debugPrint('Error fetching video categories: $e');
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

// 企業ごとにグループ化した動画プロバイダー（特集タブ用）
final groupedVideosByCompanyProvider =
    Provider<AsyncValue<Map<String, List<Map<String, dynamic>>>>>((ref) {
  final videosAsync = ref.watch(feedVideosProvider);

  return videosAsync.when(
    data: (videos) {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final video in videos) {
        final company = video['companies'] as Map<String, dynamic>?;
        final companyName = company?['name'] as String? ?? '不明な企業';
        final companyId = company?['id'] as String? ?? 'unknown';
        final key = '$companyId|$companyName';
        grouped.putIfAbsent(key, () => []).add(video);
      }
      return AsyncValue.data(grouped);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// トピックセクションモデル
class TopicSection {
  final String title;
  final List<Map<String, dynamic>> videos;
  const TopicSection({required this.title, required this.videos});
}

// トピック別動画セクションプロバイダー（特集タブ用）
final topicSectionsProvider = Provider<AsyncValue<List<TopicSection>>>((ref) {
  final videosAsync = ref.watch(feedVideosProvider);

  return videosAsync.when(
    data: (videos) {
      if (videos.isEmpty) return const AsyncValue.data([]);

      final sections = <TopicSection>[];
      final sectionNames = ref.watch(feedSectionNamesProvider).valueOrNull ?? [];
      final topicNames = sectionNames.isNotEmpty
          ? sectionNames
          : ['注目企業', '急募の企業', '今週のおすすめ企業', '若手が活躍できる企業', 'あなたが見た企業'];
      final sectionSize = (videos.length / topicNames.length).ceil().clamp(2, 10);

      for (int i = 0; i < topicNames.length; i++) {
        final start = i * sectionSize;
        if (start >= videos.length) break;
        final end = (start + sectionSize).clamp(0, videos.length);
        sections.add(TopicSection(
          title: topicNames[i],
          videos: videos.sublist(start, end),
        ));
      }

      return AsyncValue.data(sections);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// ========== フィードセクション関連プロバイダー ==========

// feed_sectionsテーブルからセクション名を取得
final feedSectionNamesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('feed_sections')
        .select('title')
        .eq('is_active', true)
        .order('sort_order');
    final list = List<Map<String, dynamic>>.from(response as List);
    if (list.isEmpty) return [];
    return list.map((e) => e['title'] as String).toList();
  } catch (e) {
    return [];
  }
});

// feed_bannersテーブルからスライドショーデータ取得
final feedBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('feed_banners')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    return [];
  }
});

// companiesテーブルから企業一覧取得（フィードセクション用）
final feedCompaniesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('companies')
        .select('id, name, industry, logo_url, catchphrase')
        .eq('is_suspended', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    return [];
  }
});

// 業種マスターデータ取得（companiesテーブルから動的取得）
final industryMasterProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('companies')
        .select('industry')
        .not('industry', 'is', null)
        .not('industry', 'eq', '');
    final list = List<Map<String, dynamic>>.from(response as List);
    final industries = list
        .map((e) => e['industry'] as String)
        .toSet()
        .toList()
      ..sort();
    return industries;
  } catch (e) {
    return defaultIndustries;
  }
});

// 視聴履歴プロバイダー
final watchHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await supabase
        .from('video_views')
        .select('*, company_videos(*, companies(*))')
        .eq('profile_id', userId)
        .order('watched_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching watch history: $e');
    return [];
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

    return response;
  } catch (e) {
    debugPrint('Error fetching video by id: $e');
    return null;
  }
});