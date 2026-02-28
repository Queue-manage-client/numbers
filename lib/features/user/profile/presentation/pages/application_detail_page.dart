// profile/presentation/pages/application_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          '応募詳細',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        foregroundColor: ColorPalette.neutral0,
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: Center(
        child: Text(
          '応募詳細ページ',
          style: TextStylePalette.subText,
        ),
      ),
    );
  }
}
