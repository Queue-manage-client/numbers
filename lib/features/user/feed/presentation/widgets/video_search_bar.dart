// feed/presentation/widgets/video_search_bar.dart
import 'package:flutter/material.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/features/user/search/presentation/pages/video_search_page.dart';

class VideoSearchBar extends StatelessWidget {
  const VideoSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true, // シート外タップで閉じる
          enableDrag: false, // Draggableを無効化
          backgroundColor: Colors.transparent,
          builder: (context) => const VideoSearchPage(),
        );
      },
      child: Container(
        height: ButtonSizePalette.button,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          border: Border.all(
            color: ColorPalette.neutral400,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, color: ColorPalette.neutral400, size: 20),
              const SizedBox(width: SpacePalette.sm),
              Text('企業を検索する', style: TextStylePalette.hintText),
            ],
          ),
        ),
      ),
    );
  }
}