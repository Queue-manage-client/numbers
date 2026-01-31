// job/presentation/widgets/radius_slider.dart
import 'package:flutter/material.dart';
import 'package:numbers/features/user/job/data/models/map_filter.dart';
import 'package:numbers/core/theme/app_theme.dart';

class RadiusSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacePalette.base),
      padding: const EdgeInsets.all(SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800.withOpacity(0.95),
        borderRadius: BorderRadius.circular(RadiusPalette.lg),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '検索範囲',
                style: TextStylePalette.smTitle,
              ),
              Text(
                '${value.toStringAsFixed(0)}km',
                style: TextStylePalette.smTitle.copyWith(
                  color: ColorPalette.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacePalette.sm),
          Row(
            children: [
              Text(
                '1km',
                style: TextStylePalette.smSubText,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ColorPalette.primaryColor,
                    inactiveTrackColor: ColorPalette.neutral600,
                    thumbColor: ColorPalette.primaryColor,
                    overlayColor: ColorPalette.primaryColor.withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                '20km',
                style: TextStylePalette.smSubText,
              ),
            ],
          ),
          // Quick select buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: RadiusOption.all.map((option) {
              final isSelected = value == option.value;
              return GestureDetector(
                onTap: () => onChanged(option.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacePalette.sm,
                    vertical: SpacePalette.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorPalette.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(RadiusPalette.mini),
                    border: Border.all(
                      color: isSelected
                          ? ColorPalette.primaryColor
                          : ColorPalette.neutral600,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontFamily: 'NotoSansJP',
                      fontSize: FontSizePalette.size12,
                      fontVariations: const [FontVariation('wght', 700)],
                      color: isSelected
                          ? ColorPalette.neutral900
                          : ColorPalette.neutral400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
