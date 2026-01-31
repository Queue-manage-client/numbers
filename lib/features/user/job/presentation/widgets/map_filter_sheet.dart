// job/presentation/widgets/map_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/user/job/data/models/map_filter.dart';
import 'package:numbers/features/user/job/presentation/providers/job_map_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class MapFilterSheet extends ConsumerWidget {
  const MapFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ColorPalette.neutral800,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RadiusPalette.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: SpacePalette.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorPalette.neutral600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(SpacePalette.base),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('絞り込み', style: TextStylePalette.smHeader),
                    TextButton(
                      onPressed: () {
                        ref.read(mapFilterProvider.notifier).reset();
                      },
                      child: Text(
                        'リセット',
                        style: TextStylePalette.guide,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: ColorPalette.neutral600, height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(SpacePalette.base),
                  children: [
                    // Job types
                    _buildSection(
                      title: '募集種別',
                      child: Wrap(
                        spacing: SpacePalette.sm,
                        runSpacing: SpacePalette.sm,
                        children: JobTypeOption.all.map((option) {
                          final isSelected =
                              filter.jobTypes.contains(option.value);
                          return _FilterChip(
                            label: option.label,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                  .read(mapFilterProvider.notifier)
                                  .toggleJobType(option.value);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // Industries
                    _buildSection(
                      title: '業種',
                      child: Wrap(
                        spacing: SpacePalette.sm,
                        runSpacing: SpacePalette.sm,
                        children: IndustryOption.all.map((option) {
                          final isSelected =
                              filter.industries.contains(option.value);
                          return _FilterChip(
                            label: option.label,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                  .read(mapFilterProvider.notifier)
                                  .toggleIndustry(option.value);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),

                    // Radius
                    _buildSection(
                      title: '検索範囲',
                      child: Wrap(
                        spacing: SpacePalette.sm,
                        runSpacing: SpacePalette.sm,
                        children: RadiusOption.all.map((option) {
                          final isSelected = filter.radiusKm == option.value;
                          return _FilterChip(
                            label: option.label,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                  .read(mapFilterProvider.notifier)
                                  .updateRadius(option.value);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: SpacePalette.lg),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(SpacePalette.base),
                child: GradientButton(
                  text: '適用する',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStylePalette.smTitle),
        const SizedBox(height: SpacePalette.sm),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacePalette.base,
          vertical: SpacePalette.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral800,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          border: Border.all(
            color: isSelected ? ColorPalette.primaryColor : ColorPalette.neutral600,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: FontSizePalette.size14,
            fontVariations: const [FontVariation('wght', 700)],
            color: isSelected ? ColorPalette.neutral900 : ColorPalette.neutral0,
          ),
        ),
      ),
    );
  }
}
