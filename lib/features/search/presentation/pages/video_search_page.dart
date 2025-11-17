import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class VideoSearchPage extends ConsumerStatefulWidget {
  const VideoSearchPage({super.key});

  @override
  ConsumerState<VideoSearchPage> createState() => _VideoSearchPageState();
}

class _VideoSearchPageState extends ConsumerState<VideoSearchPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedIndustry;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<Map<String, dynamic>> _filterVideos(
      List<Map<String, dynamic>> videos, String query, String? industry) {
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
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(feedVideosProvider);
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('動画検索'),
        backgroundColor: const Color(0xFF323232),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: Column(
        children: [
          // 検索バーとフィルタ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'キーワードで検索',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _performSearch,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                // 業界フィルタ（簡易実装）
                DropdownButtonFormField<String>(
                  value: _selectedIndustry,
                  decoration: const InputDecoration(
                    labelText: '業界で絞り込む',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('すべて')),
                    DropdownMenuItem(value: 'IT', child: Text('IT')),
                    DropdownMenuItem(value: '金融', child: Text('金融')),
                    DropdownMenuItem(value: '製造', child: Text('製造')),
                    DropdownMenuItem(value: 'サービス', child: Text('サービス')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedIndustry = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // 検索結果
          Expanded(
            child: videosAsync.when(
              data: (allVideos) {
                final filteredVideos =
                    _filterVideos(allVideos, _searchQuery, _selectedIndustry);

                if (_searchQuery.isEmpty && _selectedIndustry == null) {
                  return Center(
                    child: Text(
                      'キーワードを入力するか、業界で絞り込んでください',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (filteredVideos.isEmpty) {
                  return Center(
                    child: Text(
                      '検索結果がありません',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = filteredVideos[index];
                    final company = video['companies'] as Map<String, dynamic>?;
                    final companyId = video['company_id'] as String?;
                    final videoId = video['id'] as String?;
                    final title = video['title'] as String? ?? 'タイトルなし';
                    final description =
                        video['description'] as String? ?? '';
                    final thumbnailPath = video['thumbnail_path'] as String?;
                    final tags =
                        (video['tags'] as List<dynamic>?)?.cast<String>() ?? [];

                    String? thumbnailUrl;
                    if (thumbnailPath != null) {
                      final supabase = Supabase.instance.client;
                      thumbnailUrl = supabase.storage
                          .from('thumbnails')
                          .getPublicUrl(thumbnailPath);
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          if (companyId != null) {
                            context.go('/company/$companyId');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // サムネイル
                              if (thumbnailUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    thumbnailUrl,
                                    width: 120,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.video_library),
                                      );
                                    },
                                  ),
                                )
                              else
                                Container(
                                  width: 120,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.video_library),
                                ),
                              const SizedBox(width: 16),
                              // 情報
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF323232),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (company != null)
                                      Text(
                                        company['name'] as String? ?? '企業名不明',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: tags.take(3).map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF666666),
                                              ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('エラー: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(feedVideosProvider);
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
