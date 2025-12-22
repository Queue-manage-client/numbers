// search/presentation/pages/video_search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

// サムネイルプレースホルダー
Widget _buildPlaceholder() {
  return Container(
    width: 120,
    height: 80,
    decoration: BoxDecoration(
      color: ColorPalette.neutral200,
      borderRadius: BorderRadius.circular(RadiusPalette.base),
    ),
    child: Icon(
      Icons.video_library,
      color: ColorPalette.neutral400,
      size: 40,
    ),
  );
}

class VideoSearchPage extends HookConsumerWidget {
  const VideoSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedIndustry = useState<String?>(null);
    final showClearButton = useState(false);

    useEffect(() {
      void listener() {
        showClearButton.value = searchController.text.isNotEmpty;
      }
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    final performSearch = useCallback(() {
      searchQuery.value = searchController.text.trim();
    }, [searchController]);

    final filterVideos = useCallback((
      List<Map<String, dynamic>> videos,
      String query,
      String? industry,
    ) {
      var filtered = videos;

      // キーワード検索
      if (query.isNotEmpty) {
        filtered = filtered.where((video) {
          final title = (video['title'] as String? ?? '').toLowerCase();
          final description = (video['description'] as String? ?? '').toLowerCase();
          final tags = (video['tags'] as List<dynamic>?)?.cast<String>() ?? [];
          final company = video['companies'] as Map<String, dynamic>?;
          final companyName = (company?['name'] as String? ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              description.contains(searchLower) ||
              companyName.contains(searchLower) ||
              tags.any((tag) => tag.toLowerCase().contains(searchLower));
        }).toList();
      }

      // 業界フィルタ
      if (industry != null && industry.isNotEmpty) {
        filtered = filtered.where((video) {
          final company = video['companies'] as Map<String, dynamic>?;
          return company?['industry'] == industry;
        }).toList();
      }

      return filtered;
    }, []);

    final videosAsync = ref.watch(feedVideosProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: ColorPalette.neutral100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(RadiusPalette.lg + 8),
          topRight: Radius.circular(RadiusPalette.lg + 8),
        ),
      ),
      child: Column(
        children: [
          // ハンドルバー
          Container(
            margin: const EdgeInsets.only(top: SpacePalette.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorPalette.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '動画検索',
                    style: TextStylePalette.title,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: ColorPalette.neutral800,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: ColorPalette.neutral200,
          ),

          // 検索バーとフィルタ
          Padding(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  style: TextStylePalette.normalText,
                  decoration: InputDecoration(
                    hintText: 'キーワードで検索',
                    hintStyle: TextStylePalette.hintText,
                    prefixIcon: Icon(
                      Icons.search,
                      color: ColorPalette.neutral400,
                    ),
                    suffixIcon: showClearButton.value
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: ColorPalette.neutral400,
                            ),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => performSearch(),
                ),

                const SizedBox(height: SpacePalette.base),
                
                // 業界フィルタ
                DropdownButtonFormField<String>(
                  value: selectedIndustry.value,
                  style: TextStylePalette.normalText,
                  decoration: InputDecoration(
                    labelText: '業界で絞り込む',
                    labelStyle: TextStylePalette.smTitle,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('すべて', style: TextStylePalette.normalText),
                    ),
                    DropdownMenuItem(
                      value: 'IT',
                      child: Text('IT', style: TextStylePalette.normalText),
                    ),
                    DropdownMenuItem(
                      value: '金融',
                      child: Text('金融', style: TextStylePalette.normalText),
                    ),
                    DropdownMenuItem(
                      value: '製造',
                      child: Text('製造', style: TextStylePalette.normalText),
                    ),
                    DropdownMenuItem(
                      value: 'サービス',
                      child: Text('サービス', style: TextStylePalette.normalText),
                    ),
                  ],
                  onChanged: (value) {
                    selectedIndustry.value = value;
                  },
                ),

                const SizedBox(height: SpacePalette.base),
                
                // 検索ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: performSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('検索'),
                  ),
                ),
              ],
            ),
          ),

          // 検索結果
          Expanded(
            child: videosAsync.when(
              data: (allVideos) {
                final filteredVideos = filterVideos(
                  allVideos,
                  searchQuery.value,
                  selectedIndustry.value,
                );

                if (searchQuery.value.isEmpty && selectedIndustry.value == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacePalette.base),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 80,
                            color: ColorPalette.neutral400,
                          ),
                          const SizedBox(height: SpacePalette.lg),
                          Text(
                            'キーワードを入力するか、\n業界で絞り込んでください',
                            style: TextStylePalette.subText,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredVideos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: ColorPalette.neutral400,
                        ),
                        const SizedBox(height: SpacePalette.lg),
                        Text(
                          '検索結果がありません',
                          style: TextStylePalette.subText,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = filteredVideos[index];
                    final company = video['companies'] as Map<String, dynamic>?;
                    final companyId = video['company_id'] as String?;
                    final title = video['title'] as String? ?? 'タイトルなし';
                    final description = video['description'] as String? ?? '';
                    final thumbnailPath = video['thumbnail_path'] as String?;
                    final tags = (video['tags'] as List<dynamic>?)?.cast<String>() ?? [];

                    String? thumbnailUrl;
                    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
                      final supabase = Supabase.instance.client;
                      thumbnailUrl = supabase.storage
                          .from('thumbnails')
                          .getPublicUrl(thumbnailPath);
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: SpacePalette.sm),
                      child: InkWell(
                        onTap: () {
                          if (companyId != null) {
                            Navigator.of(context).pop(); // モーダルを閉じる
                            context.go('/company/$companyId');
                          }
                        },
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(SpacePalette.base),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // サムネイル
                              ClipRRect(
                                borderRadius: BorderRadius.circular(RadiusPalette.base),
                                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        thumbnailUrl,
                                        width: 120,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholder();
                                        },
                                      )
                                    : _buildPlaceholder(),
                              ),
                              const SizedBox(width: SpacePalette.base),
                              
                              // 情報
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStylePalette.smListTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: SpacePalette.xs),
                                    
                                    if (company != null)
                                      Text(
                                        company['name'] as String? ?? '企業名不明',
                                        style: TextStylePalette.subText,
                                      ),
                                    
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: SpacePalette.xs),
                                      Text(
                                        description,
                                        style: TextStylePalette.smListLeading,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    
                                    if (tags.isNotEmpty) ...[
                                      const SizedBox(height: SpacePalette.sm),
                                      Wrap(
                                        spacing: SpacePalette.xs,
                                        runSpacing: SpacePalette.xs,
                                        children: tags.take(3).map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: SpacePalette.sm,
                                              vertical: SpacePalette.xs / 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ColorPalette.neutral200,
                                              borderRadius: BorderRadius.circular(RadiusPalette.mini),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStylePalette.miniTitle,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: ColorPalette.primaryColor,
                      ),
                      const SizedBox(height: SpacePalette.lg),
                      Text(
                        'エラーが発生しました',
                        style: TextStylePalette.header,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        'もう一度お試しください',
                        style: TextStylePalette.subText,
                      ),
                      const SizedBox(height: SpacePalette.lg),
                      OutlinedButton(
                        onPressed: () {
                          ref.invalidate(feedVideosProvider);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorPalette.primaryColor,
                          side: const BorderSide(
                            color: ColorPalette.primaryColor,
                            width: 2,
                          ),
                          minimumSize: const Size(120, ButtonSizePalette.button),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RadiusPalette.base),
                          ),
                        ),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}