// intern/presentation/pages/intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';

class InternListPage extends ConsumerStatefulWidget {
  const InternListPage({super.key});

  @override
  ConsumerState<InternListPage> createState() => _InternListPageState();
}

class _InternListPageState extends ConsumerState<InternListPage> {
  final _searchController = TextEditingController();

  List<String> _getIndustries(WidgetRef ref) {
    final dbIndustries = ref.watch(industryMasterProvider).valueOrNull;
    return (dbIndustries != null && dbIndustries.isNotEmpty) ? dbIndustries : defaultIndustries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredInternshipsProvider);
    final selectedIndustry = ref.watch(internIndustryFilterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'インターン一覧',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacePalette.base,
              vertical: SpacePalette.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(internSearchQueryProvider.notifier).state = value;
              },
              style: const TextStyle(
                fontFamily: 'NotoSansJP',
                fontSize: FontSizePalette.size14,
                color: ColorPalette.neutral0,
              ),
              decoration: InputDecoration(
                hintText: 'キーワードで検索...',
                hintStyle: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size14,
                  color: ColorPalette.neutral400,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ColorPalette.neutral400,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: ColorPalette.neutral400,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(internSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: ColorPalette.neutral800,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: SpacePalette.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: const BorderSide(
                    color: ColorPalette.neutral600,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                  borderSide: BorderSide(
                    color: ColorPalette.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 業種フィルターチップ
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: SpacePalette.base),
              children: [
                // 「全て」チップ
                Padding(
                  padding: const EdgeInsets.only(right: SpacePalette.sm),
                  child: ChoiceChip(
                    label: const Text('全て'),
                    selected: selectedIndustry == null,
                    onSelected: (_) {
                      ref.read(internIndustryFilterProvider.notifier).state =
                          null;
                    },
                    selectedColor: ColorPalette.primaryColor,
                    backgroundColor: ColorPalette.neutral800,
                    labelStyle: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size12,
                      fontVariations: const [FontVariation('wght', 600)],
                      color: selectedIndustry == null
                          ? Colors.white
                          : ColorPalette.neutral400,
                    ),
                    side: BorderSide(
                      color: selectedIndustry == null
                          ? ColorPalette.primaryColor
                          : ColorPalette.neutral600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(RadiusPalette.base),
                    ),
                  ),
                ),
                // 業種チップ
                ..._getIndustries(ref).map((industry) {
                  final isSelected = selectedIndustry == industry;
                  return Padding(
                    padding:
                        const EdgeInsets.only(right: SpacePalette.sm),
                    child: ChoiceChip(
                      label: Text(industry),
                      selected: isSelected,
                      onSelected: (_) {
                        ref
                            .read(internIndustryFilterProvider.notifier)
                            .state = isSelected ? null : industry;
                      },
                      selectedColor: ColorPalette.primaryColor,
                      backgroundColor: ColorPalette.neutral800,
                      labelStyle: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: FontSizePalette.size12,
                        fontVariations: const [
                          FontVariation('wght', 600)
                        ],
                        color: isSelected
                            ? Colors.white
                            : ColorPalette.neutral400,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? ColorPalette.primaryColor
                            : ColorPalette.neutral600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(RadiusPalette.base),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: SpacePalette.sm),

          // リスト部分
          Expanded(
            child: filteredAsync.when(
              data: (internships) {
                // 結果件数
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${internships.length}件のインターン',
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: FontSizePalette.size12,
                            fontVariations: const [
                              FontVariation('wght', 500)
                            ],
                            color: ColorPalette.neutral400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacePalette.sm),
                    Expanded(
                      child: internships.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: ColorPalette.neutral400,
                                  ),
                                  const SizedBox(height: SpacePalette.base),
                                  Text(
                                    '該当するインターンが見つかりません',
                                    style: TextStylePalette.subText,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacePalette.base,
                              ),
                              itemCount: internships.length,
                              itemBuilder: (context, index) {
                                final internship = internships[index];
                                final company = internship['companies']
                                    as Map<String, dynamic>?;
                                final tags =
                                    (internship['tags'] as List<dynamic>?)
                                            ?.whereType<String>()
                                            .toList() ??
                                        [];

                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: SpacePalette.base),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.neutral800,
                                    borderRadius: BorderRadius.circular(
                                        RadiusPalette.lg),
                                    border: Border.all(
                                        color: ColorPalette.neutral600),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                        RadiusPalette.lg),
                                    onTap: () => context.push(
                                        '/interns/${internship['id']}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          SpacePalette.base),
                                      child: Stack(
                                        children: [
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            internship['title'] ??
                                                'タイトル未設定',
                                            style:
                                                TextStylePalette.smListTitle,
                                          ),
                                          const SizedBox(
                                              height: SpacePalette.sm),
                                          Text(
                                            company?['name'] ?? '企業名未設定',
                                            style:
                                                TextStylePalette.subText,
                                          ),
                                          const SizedBox(
                                              height: SpacePalette.xs),
                                          Text(
                                            '期間: ${internship['start_date'] ?? '未定'} 〜 ${internship['end_date'] ?? '未定'}',
                                            style:
                                                TextStylePalette.smSubText,
                                          ),
                                          if (tags.isNotEmpty) ...[
                                            const SizedBox(
                                                height: SpacePalette.sm),
                                            Wrap(
                                              spacing: SpacePalette.xs,
                                              runSpacing: SpacePalette.xs,
                                              children:
                                                  tags.take(3).map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal:
                                                        SpacePalette.sm,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: ColorPalette
                                                        .neutral600,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      RadiusPalette.mini,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'NotoSansJP',
                                                      fontSize:
                                                          FontSizePalette
                                                              .size12,
                                                      fontVariations: const [
                                                        FontVariation(
                                                            'wght', 500)
                                                      ],
                                                      color: ColorPalette
                                                          .neutral300,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                          // 右上に企業ロゴ
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: () {
                                              final logoUrl = company?['logo_url'] as String?;
                                              if (logoUrl != null && logoUrl.isNotEmpty) {
                                                return CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage: NetworkImage(logoUrl),
                                                  backgroundColor: ColorPalette.neutral600,
                                                );
                                              }
                                              return CircleAvatar(
                                                radius: 16,
                                                backgroundColor: ColorPalette.neutral900,
                                                child: Icon(Icons.business, size: 16, color: ColorPalette.neutral0),
                                              );
                                            }(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: ColorPalette.primaryColor,
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'エラー: $error',
                  style: TextStylePalette.normalText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
