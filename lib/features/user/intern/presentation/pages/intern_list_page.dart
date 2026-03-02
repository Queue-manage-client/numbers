// intern/presentation/pages/intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class InternListPage extends ConsumerStatefulWidget {
  const InternListPage({super.key});

  @override
  ConsumerState<InternListPage> createState() => _InternListPageState();
}

class _InternListPageState extends ConsumerState<InternListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPrefecture;
  String? _selectedAmount;
  String? _selectedDays;

  static const List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  static const List<String> _amountOptions = [
    '無給',
    '〜5,000円/日',
    '5,000〜10,000円/日',
    '10,000円〜/日',
  ];

  static const List<String> _daysOptions = [
    '1日',
    '2〜3日',
    '1週間',
    '2週間',
    '1ヶ月以上',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterInternships(List<Map<String, dynamic>> internships) {
    return internships.where((internship) {
      // キーワード検索
      if (_searchQuery.isNotEmpty) {
        final title = (internship['title'] ?? '').toString().toLowerCase();
        final company = internship['companies'] as Map<String, dynamic>?;
        final companyName = (company?['name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !companyName.contains(query)) {
          return false;
        }
      }

      // 都道府県フィルター
      if (_selectedPrefecture != null) {
        final location = (internship['location'] ?? '').toString();
        if (!location.contains(_selectedPrefecture!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    String? tempPrefecture = _selectedPrefecture;
    String? tempAmount = _selectedAmount;
    String? tempDays = _selectedDays;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.neutral800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusPalette.lg)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ハンドル
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorPalette.neutral600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpacePalette.base),
                      Text('絞り込み', style: TextStylePalette.smHeader),
                      const SizedBox(height: SpacePalette.lg),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 都道府県
                            Text('都道府県', style: TextStylePalette.smTitle),
                            const SizedBox(height: SpacePalette.sm),
                            DropdownButtonFormField<String>(
                              value: tempPrefecture,
                              dropdownColor: ColorPalette.neutral800,
                              decoration: const InputDecoration(hintText: '都道府県を選択'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('すべて')),
                                ..._prefectures.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p, style: TextStylePalette.normalText),
                                )),
                              ],
                              onChanged: (value) => setSheetState(() => tempPrefecture = value),
                            ),
                            const SizedBox(height: SpacePalette.base),

                            // 金額
                            Text('報酬', style: TextStylePalette.smTitle),
                            const SizedBox(height: SpacePalette.sm),
                            DropdownButtonFormField<String>(
                              value: tempAmount,
                              dropdownColor: ColorPalette.neutral800,
                              decoration: const InputDecoration(hintText: '報酬を選択'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('すべて')),
                                ..._amountOptions.map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a, style: TextStylePalette.normalText),
                                )),
                              ],
                              onChanged: (value) => setSheetState(() => tempAmount = value),
                            ),
                            const SizedBox(height: SpacePalette.base),

                            // 日数
                            Text('期間', style: TextStylePalette.smTitle),
                            const SizedBox(height: SpacePalette.sm),
                            DropdownButtonFormField<String>(
                              value: tempDays,
                              dropdownColor: ColorPalette.neutral800,
                              decoration: const InputDecoration(hintText: '期間を選択'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('すべて')),
                                ..._daysOptions.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d, style: TextStylePalette.normalText),
                                )),
                              ],
                              onChanged: (value) => setSheetState(() => tempDays = value),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: SpacePalette.base),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempPrefecture = null;
                                  tempAmount = null;
                                  tempDays = null;
                                });
                              },
                              child: const Text('リセット'),
                            ),
                          ),
                          const SizedBox(width: SpacePalette.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPrefecture = tempPrefecture;
                                  _selectedAmount = tempAmount;
                                  _selectedDays = tempDays;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('適用'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedPrefecture != null) count++;
    if (_selectedAmount != null) count++;
    if (_selectedDays != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final internshipsAsync = ref.watch(internshipsProvider);
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
          Container(
            color: ColorPalette.neutral800,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacePalette.base,
              vertical: SpacePalette.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStylePalette.normalText,
                    decoration: InputDecoration(
                      hintText: '企業名・キーワードで検索',
                      hintStyle: TextStylePalette.hintText,
                      filled: true,
                      fillColor: ColorPalette.neutral900,
                      prefixIcon: const Icon(Icons.search, color: ColorPalette.neutral400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RadiusPalette.base),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                        vertical: SpacePalette.inner,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: SpacePalette.sm),
                TextButton(
                  onPressed: _showFilterSheet,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '絞り込み',
                        style: TextStyle(color: ColorPalette.neutral0),
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(width: SpacePalette.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorPalette.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: ColorPalette.neutral0,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // フィルターチップ表示
          if (_selectedPrefecture != null || _selectedAmount != null || _selectedDays != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacePalette.base,
                vertical: SpacePalette.sm,
              ),
              child: Wrap(
                spacing: SpacePalette.sm,
                runSpacing: SpacePalette.xs,
                children: [
                  if (_selectedPrefecture != null)
                    Chip(
                      label: Text(_selectedPrefecture!, style: TextStylePalette.smText),
                      deleteIcon: const Icon(Icons.close, size: 16, color: ColorPalette.neutral400),
                      onDeleted: () => setState(() => _selectedPrefecture = null),
                    ),
                  if (_selectedAmount != null)
                    Chip(
                      label: Text(_selectedAmount!, style: TextStylePalette.smText),
                      deleteIcon: const Icon(Icons.close, size: 16, color: ColorPalette.neutral400),
                      onDeleted: () => setState(() => _selectedAmount = null),
                    ),
                  if (_selectedDays != null)
                    Chip(
                      label: Text(_selectedDays!, style: TextStylePalette.smText),
                      deleteIcon: const Icon(Icons.close, size: 16, color: ColorPalette.neutral400),
                      onDeleted: () => setState(() => _selectedDays = null),
                    ),
                ],
              ),
            ),

          // インターン一覧
          Expanded(
            child: internshipsAsync.when(
              data: (internships) {
                final filtered = _filterInternships(internships);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      internships.isEmpty ? 'インターンがありません' : '条件に一致するインターンがありません',
                      style: TextStylePalette.subText,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final internship = filtered[index];
                    final company = internship['companies'] as Map<String, dynamic>?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: SpacePalette.base),
                      decoration: BoxDecoration(
                        color: ColorPalette.neutral800,
                        borderRadius: BorderRadius.circular(RadiusPalette.lg),
                        border: Border.all(color: ColorPalette.neutral600),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(SpacePalette.base),
                        title: Text(
                          internship['title'] ?? 'タイトル未設定',
                          style: TextStylePalette.smListTitle,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: SpacePalette.sm),
                            Text(
                              company?['name'] ?? '企業名未設定',
                              style: TextStylePalette.subText,
                            ),
                            const SizedBox(height: SpacePalette.xs),
                            Text(
                              '期間: ${internship['start_date'] ?? '未定'} 〜 ${internship['end_date'] ?? '未定'}',
                              style: TextStylePalette.smSubText,
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: ColorPalette.neutral400,
                        ),
                        onTap: () => context.push('/interns/${internship['id']}'),
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
