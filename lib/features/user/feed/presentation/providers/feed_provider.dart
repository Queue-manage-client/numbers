// feed/presentation/providers/feed_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/core/providers/app_config_provider.dart';

// 業種フォールバックリスト（DBから取得できない場合に使用）
const List<String> defaultIndustries = [
  'IT', '金融', '建築・土木', '製造', 'サービス', '小売', '医療・福祉', '教育',
];

// Supabaseクライアントプロバイダー
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// フィード動画取得プロバイダー（公開動画のみ、署名付きURL事前解決済み）
final feedVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase
        .from('company_videos')
        .select('*, companies(*), jobs(*)')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(50);

    final videos = List<Map<String, dynamic>>.from(response);

    // 署名付きURLとサムネイルURLを事前に一括解決（各動画ページでの遅延を排除）
    await Future.wait(videos.map((video) async {
      final videoPath = video['video_path'] as String?;
      if (videoPath == null || videoPath.isEmpty) return;
      if (videoPath.startsWith('http')) {
        video['video_url'] = videoPath;
      } else {
        try {
          video['video_url'] = await supabase.storage
              .from('company-videos')
              .createSignedUrl(videoPath, 3600);
        } catch (e) {
          debugPrint('Error pre-resolving video URL: $e');
        }
      }

      // サムネイルURLを事前解決（公開バケット、同期処理）
      final thumbnailPath = video['thumbnail_path'] as String?;
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        if (thumbnailPath.startsWith('http')) {
          video['thumbnail_url'] = thumbnailPath;
        } else {
          video['thumbnail_url'] = supabase.storage
              .from('company-thumbnails')
              .getPublicUrl(thumbnailPath);
        }
      }
    }));

    return videos;
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
      // DB設定 → feed_sections → ハードコードフォールバックの優先順位
      List<String> fallbackNames;
      try {
        final configValue =
            ref.watch(appConfigProvider('feed_section_fallback_names')).valueOrNull;
        if (configValue is List && (configValue).isNotEmpty) {
          fallbackNames = configValue.cast<String>();
        } else {
          fallbackNames = ['注目企業', '急募の企業', '今週のおすすめ企業', '若手が活躍できる企業', 'あなたが見た企業'];
        }
      } catch (_) {
        fallbackNames = ['注目企業', '急募の企業', '今週のおすすめ企業', '若手が活躍できる企業', 'あなたが見た企業'];
      }
      final topicNames = sectionNames.isNotEmpty ? sectionNames : fallbackNames;
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

// セクションモデル（動画セクション or 企業セクション）
class FeedSection {
  final String id;
  final String title;
  final String sectionType; // 'video', 'company', 'watched_history'
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> companies;
  final int sortOrder;

  const FeedSection({
    required this.id,
    required this.title,
    this.sectionType = 'video',
    this.videos = const [],
    this.companies = const [],
    this.sortOrder = 0,
  });
}

// 特集セクション取得プロバイダー（DB駆動、管理者設定を反映）
final feedSectionsProvider = FutureProvider<List<FeedSection>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final sections = await supabase
        .from('feed_sections')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    if ((sections as List).isEmpty) {
      // DB にセクションがない場合はフォールバック（全企業を均等分割）
      return _buildFallbackSections(ref);
    }

    final result = <FeedSection>[];
    final allCompanies = await ref.watch(feedCompaniesProvider.future);

    for (final section in sections) {
      final sectionId = section['id'] as String;
      final sectionType = section['section_type'] as String? ?? 'video';

      if (sectionType == 'company') {
        // 企業セクション: 企業データを使う（将来feed_section_companiesテーブルで紐付け可能）
        // 現状はsort_orderに基づいてallCompaniesをスライス
        final offset = (section['company_offset'] as int?) ?? 0;
        final limit = (section['company_limit'] as int?) ?? 5;
        final sliceStart = offset.clamp(0, allCompanies.length);
        final sliceEnd = (offset + limit).clamp(0, allCompanies.length);
        result.add(FeedSection(
          id: sectionId,
          title: section['title'] as String? ?? '',
          sectionType: 'company',
          companies: allCompanies.sublist(sliceStart, sliceEnd),
          sortOrder: section['sort_order'] as int? ?? 0,
        ));
      } else if (sectionType == 'watched_history') {
        // 視聴履歴セクション
        result.add(FeedSection(
          id: sectionId,
          title: section['title'] as String? ?? 'あなたが見た企業',
          sectionType: 'watched_history',
          sortOrder: section['sort_order'] as int? ?? 0,
        ));
      } else {
        // 動画セクション: feed_section_videosから取得
        final videosResponse = await supabase
            .from('feed_section_videos')
            .select('*, company_videos(*, companies(*))')
            .eq('section_id', sectionId)
            .order('sort_order', ascending: true);

        final videos = <Map<String, dynamic>>[];
        for (final sv in videosResponse) {
          final videoData = sv['company_videos'];
          if (videoData == null) continue;
          final video = Map<String, dynamic>.from(videoData as Map);

          // セクション固有のサムネイルを優先
          final sectionThumb = sv['thumbnail_url'] as String?;
          final sectionHighlightThumb = sv['highlight_thumbnail_url'] as String?;

          if (sectionThumb != null && sectionThumb.isNotEmpty) {
            video['thumbnail_url'] = sectionThumb;
          } else {
            // フォールバック: 動画自体のサムネイル
            final thumbnailPath = video['thumbnail_path'] as String?;
            if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
              try {
                video['thumbnail_url'] = thumbnailPath.startsWith('http')
                    ? thumbnailPath
                    : supabase.storage
                        .from('company-thumbnails')
                        .getPublicUrl(thumbnailPath);
              } catch (_) {
                video['thumbnail_url'] = '';
              }
            }
          }

          // 注目セクション用の縦長サムネイル
          if (sectionHighlightThumb != null && sectionHighlightThumb.isNotEmpty) {
            video['highlight_thumbnail_url'] = sectionHighlightThumb;
          }

          videos.add(video);
        }

        result.add(FeedSection(
          id: sectionId,
          title: section['title'] as String? ?? '',
          sectionType: 'video',
          videos: videos,
          sortOrder: section['sort_order'] as int? ?? 0,
        ));
      }
    }
    return result;
  } catch (e) {
    debugPrint('Error fetching feed sections: $e');
    return _buildFallbackSections(ref);
  }
});

// DBにセクションがない場合のフォールバック
Future<List<FeedSection>> _buildFallbackSections(Ref ref) async {
  try {
    final allCompanies = await ref.watch(feedCompaniesProvider.future);
    return [
      FeedSection(
        id: 'fallback_featured',
        title: '注目企業',
        sectionType: 'company',
        companies: allCompanies.take(5).toList(),
      ),
      FeedSection(
        id: 'fallback_popular',
        title: '急募の企業',
        sectionType: 'company',
        companies: allCompanies.length > 5
            ? allCompanies.sublist(5, (allCompanies.length).clamp(5, 10))
            : [],
      ),
      // 「あなたが見た企業」はUI側で常に末尾に固定表示されるためここには含めない
    ];
  } catch (_) {
    return [];
  }
}

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