// profile/presentation/pages/privacy_policy_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/providers/app_config_provider.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(legalDocumentProvider('privacy_policy'));

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        title: Text(
          'プライバシーポリシー',
          style: TextStylePalette.title,
        ),
        backgroundColor: ColorPalette.neutral900,
        elevation: 0,
      ),
      body: docAsync.when(
        data: (doc) {
          if (doc == null) {
            return const Center(
              child: Text('プライバシーポリシーを読み込めませんでした',
                  style: TextStyle(color: ColorPalette.neutral400)),
            );
          }

          final title = doc['title'] as String? ?? '';
          final lastUpdated = doc['last_updated_label'] as String? ?? '';
          final sections = (doc['sections'] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacePalette.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStylePalette.smHeader),
                const SizedBox(height: SpacePalette.base),
                Text(lastUpdated, style: TextStylePalette.smSubText),
                const SizedBox(height: SpacePalette.lg),
                ...sections.map((section) {
                  final s = section as Map<String, dynamic>;
                  return _buildSection(
                    s['title'] as String? ?? '',
                    s['content'] as String? ?? '',
                  );
                }),
                const SizedBox(height: SpacePalette.lg * 2),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryColor),
        ),
        error: (_, __) => const Center(
          child: Text('プライバシーポリシーを読み込めませんでした',
              style: TextStyle(color: ColorPalette.neutral400)),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacePalette.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStylePalette.smTitle),
          const SizedBox(height: SpacePalette.sm),
          Text(content, style: TextStylePalette.subText),
        ],
      ),
    );
  }
}
