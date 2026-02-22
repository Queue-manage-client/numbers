// intern/presentation/pages/intern_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/features/user/intern/presentation/providers/intern_provider.dart';
import 'package:numbers/core/theme/app_theme.dart';

class InternListPage extends ConsumerWidget {
  const InternListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: internshipsAsync.when(
        data: (internships) {
          if (internships.isEmpty) {
            return Center(
              child: Text(
                'インターンがありません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(SpacePalette.base),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final internship = internships[index];
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
    );
  }
}
