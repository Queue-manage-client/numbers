// intern/presentation/pages/intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/features/user/job/presentation/providers/job_provider.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';
import 'package:numbers/features/user/feed/presentation/providers/feed_provider.dart';

class InternListPage extends ConsumerStatefulWidget {
  const InternListPage({super.key});

  @override
  ConsumerState<InternListPage> createState() => _InternListPageState();
}

class _InternListPageState extends ConsumerState<InternListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _internSearchController = TextEditingController();
  final _jobSearchController = TextEditingController();
  final _tabBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPageTour();
    });
  }

  Future<void> _startPageTour() async {
    await AppTourService.showPageTourIfNeeded(
      context: context,
      pageKey: 'intern_list',
      targets: [
        AppTourService.createTarget(
          key: _tabBarKey,
          title: 'タブ切り替え',
          description: '「インターン」と「求人」をタブで切り替えられます。それぞれキーワード検索や業種フィルターで絞り込めます。',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _internSearchController.dispose();
    _jobSearchController.dispose();
    super.dispose();
  }

  List<String> _getIndustries(WidgetRef ref) {
    final dbIndustries = ref.watch(industryMasterProvider).valueOrNull;
    return (dbIndustries != null && dbIndustries.isNotEmpty)
        ? dbIndustries
        : defaultIndustries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'インターン・求人',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
        bottom: TabBar(
          key: _tabBarKey,
          controller: _tabController,
          indicatorColor: ColorPalette.primaryColor,
          labelColor: ColorPalette.primaryColor,
          unselectedLabelColor: ColorPalette.neutral500,
          dividerColor: ColorPalette.neutral600,
          dividerHeight: 0.5,
          tabs: const [
            Tab(text: 'インターン'),
            Tab(text: '求人'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InternTab(
            searchController: _internSearchController,
            getIndustries: _getIndustries,
          ),
          _JobTab(
            searchController: _jobSearchController,
            getIndustries: _getIndustries,
          ),
        ],
      ),
    );
  }
}

// ========== インターンタブ ==========

class _InternTab extends ConsumerWidget {
  final TextEditingController searchController;
  final List<String> Function(WidgetRef ref) getIndustries;

  const _InternTab({
    required this.searchController,
    required this.getIndustries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredInternshipsProvider);
    final selectedIndustry = ref.watch(internIndustryFilterProvider);

    return Column(
      children: [
        // 検索バー
        _SearchBar(
          controller: searchController,
          hintText: 'インターンを検索...',
          onChanged: (value) {
            ref.read(internSearchQueryProvider.notifier).state = value;
          },
          onClear: () {
            searchController.clear();
            ref.read(internSearchQueryProvider.notifier).state = '';
          },
        ),

        // 業種フィルター
        _IndustryFilterChips(
          industries: getIndustries(ref),
          selectedIndustry: selectedIndustry,
          onSelected: (industry) {
            ref.read(internIndustryFilterProvider.notifier).state = industry;
          },
        ),

        const SizedBox(height: SpacePalette.sm),

        // リスト
        Expanded(
          child: filteredAsync.when(
            data: (internships) {
              return Column(
                children: [
                  _ResultCount(count: internships.length, label: 'インターン'),
                  const SizedBox(height: SpacePalette.sm),
                  Expanded(
                    child: internships.isEmpty
                        ? _EmptyState(message: '該当するインターンが見つかりません')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.base,
                            ),
                            itemCount: internships.length,
                            itemBuilder: (context, index) {
                              final internship = internships[index];
                              return _InternCard(internship: internship);
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
              child: Text('エラー: $error', style: TextStylePalette.normalText),
            ),
          ),
        ),
      ],
    );
  }
}

// ========== 求人タブ ==========

// 求人用フィルタープロバイダー
final jobSearchQueryProvider = StateProvider<String>((ref) => '');
final jobIndustryFilterProvider = StateProvider<String?>((ref) => null);

final filteredJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final query = ref.watch(jobSearchQueryProvider).toLowerCase();
  final industry = ref.watch(jobIndustryFilterProvider);

  return jobsAsync.whenData((jobs) {
    return jobs.where((job) {
      // テキスト検索
      if (query.isNotEmpty) {
        final title = job.title.toLowerCase();
        final companyName = (job.company?.name ?? '').toLowerCase();
        final category = (job.jobCategory ?? '').toLowerCase();
        if (!title.contains(query) &&
            !companyName.contains(query) &&
            !category.contains(query)) {
          return false;
        }
      }
      // 業種フィルター
      if (industry != null) {
        final companyIndustry = job.company?.industry;
        if (companyIndustry != industry) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

class _JobTab extends ConsumerWidget {
  final TextEditingController searchController;
  final List<String> Function(WidgetRef ref) getIndustries;

  const _JobTab({
    required this.searchController,
    required this.getIndustries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredJobsProvider);
    final selectedIndustry = ref.watch(jobIndustryFilterProvider);

    return Column(
      children: [
        // 検索バー
        _SearchBar(
          controller: searchController,
          hintText: '求人を検索...',
          onChanged: (value) {
            ref.read(jobSearchQueryProvider.notifier).state = value;
          },
          onClear: () {
            searchController.clear();
            ref.read(jobSearchQueryProvider.notifier).state = '';
          },
        ),

        // 業種フィルター
        _IndustryFilterChips(
          industries: getIndustries(ref),
          selectedIndustry: selectedIndustry,
          onSelected: (industry) {
            ref.read(jobIndustryFilterProvider.notifier).state = industry;
          },
        ),

        const SizedBox(height: SpacePalette.sm),

        // リスト
        Expanded(
          child: filteredAsync.when(
            data: (jobs) {
              return Column(
                children: [
                  _ResultCount(count: jobs.length, label: '求人'),
                  const SizedBox(height: SpacePalette.sm),
                  Expanded(
                    child: jobs.isEmpty
                        ? _EmptyState(message: '該当する求人が見つかりません')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacePalette.base,
                            ),
                            itemCount: jobs.length,
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              return _JobCard(job: job);
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
              child: Text('エラー: $error', style: TextStylePalette.normalText),
            ),
          ),
        ),
      ],
    );
  }
}

// ========== 共通ウィジェット ==========

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacePalette.base,
        vertical: SpacePalette.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'NotoSansJP',
          fontSize: FontSizePalette.size14,
          color: ColorPalette.neutral0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: FontSizePalette.size14,
            color: ColorPalette.neutral400,
          ),
          prefixIcon: const Icon(Icons.search, color: ColorPalette.neutral400),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: ColorPalette.neutral400, size: 20),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: ColorPalette.neutral800,
          contentPadding: const EdgeInsets.symmetric(vertical: SpacePalette.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            borderSide: const BorderSide(
                color: ColorPalette.neutral600, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            borderSide:
                BorderSide(color: ColorPalette.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _IndustryFilterChips extends StatelessWidget {
  final List<String> industries;
  final String? selectedIndustry;
  final ValueChanged<String?> onSelected;

  const _IndustryFilterChips({
    required this.industries,
    required this.selectedIndustry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: SpacePalette.sm),
            child: ChoiceChip(
              label: const Text('全て'),
              selected: selectedIndustry == null,
              onSelected: (_) => onSelected(null),
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
                borderRadius: BorderRadius.circular(RadiusPalette.base),
              ),
            ),
          ),
          ...industries.map((industry) {
            final isSelected = selectedIndustry == industry;
            return Padding(
              padding: const EdgeInsets.only(right: SpacePalette.sm),
              child: ChoiceChip(
                label: Text(industry),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : industry),
                selectedColor: ColorPalette.primaryColor,
                backgroundColor: ColorPalette.neutral800,
                labelStyle: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: FontSizePalette.size12,
                  fontVariations: const [FontVariation('wght', 600)],
                  color: isSelected ? Colors.white : ColorPalette.neutral400,
                ),
                side: BorderSide(
                  color: isSelected
                      ? ColorPalette.primaryColor
                      : ColorPalette.neutral600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusPalette.base),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  final int count;
  final String label;

  const _ResultCount({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count件の$label',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: FontSizePalette.size12,
            fontVariations: const [FontVariation('wght', 500)],
            color: ColorPalette.neutral400,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: ColorPalette.neutral400),
          const SizedBox(height: SpacePalette.base),
          Text(message, style: TextStylePalette.subText),
        ],
      ),
    );
  }
}

// ========== カードウィジェット ==========

class _InternCard extends StatelessWidget {
  final Map<String, dynamic> internship;

  const _InternCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    final company = internship['companies'] as Map<String, dynamic>?;
    final tags = (internship['tags'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        onTap: () => context.push('/interns/${internship['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    internship['title'] ?? 'タイトル未設定',
                    style: TextStylePalette.smListTitle,
                  ),
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
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: SpacePalette.sm),
                    Wrap(
                      spacing: SpacePalette.xs,
                      runSpacing: SpacePalette.xs,
                      children: tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacePalette.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorPalette.neutral600,
                            borderRadius:
                                BorderRadius.circular(RadiusPalette.mini),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontFamily: 'NotoSansJP',
                              fontSize: FontSizePalette.size12,
                              fontVariations: const [
                                FontVariation('wght', 500)
                              ],
                              color: ColorPalette.neutral300,
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
                child: _CompanyLogo(company: company),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final salaryDisplay = job.salaryRangeDisplay;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        onTap: () => context.push('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(SpacePalette.base),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStylePalette.smListTitle,
                  ),
                  const SizedBox(height: SpacePalette.sm),
                  Text(
                    job.company?.name ?? '企業名未設定',
                    style: TextStylePalette.subText,
                  ),
                  const SizedBox(height: SpacePalette.xs),
                  // カテゴリ・雇用形態・勤務地
                  Text(
                    [
                      job.jobCategory,
                      _jobTypeLabel(job.jobType),
                      job.location,
                    ].where((s) => s != null && s.isNotEmpty).join(' / '),
                    style: TextStylePalette.smSubText,
                  ),
                  if (salaryDisplay.isNotEmpty) ...[
                    const SizedBox(height: SpacePalette.xs),
                    Text(
                      salaryDisplay,
                      style: TextStylePalette.smSubText.copyWith(
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              // 右上に企業ロゴ
              Positioned(
                top: 0,
                right: 0,
                child: _CompanyLogo(
                  company: job.company != null
                      ? {'logo_url': job.company!.logoUrl}
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _jobTypeLabel(String? type) {
    switch (type) {
      case 'part_time':
        return 'アルバイト';
      case 'full_time':
        return '正社員';
      case 'new_grad':
        return '新卒';
      case 'mid_career':
        return '中途';
      default:
        return null;
    }
  }
}

class _CompanyLogo extends StatelessWidget {
  final Map<String, dynamic>? company;

  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
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
  }
}
