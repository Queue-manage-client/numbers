// company/presentation/pages/company_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';

class CompanyDetailPage extends ConsumerWidget {
  const CompanyDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = GoRouterState.of(context).pathParameters['id'] ?? '';
    final companyAsync = ref.watch(companyProvider(companyId));
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.neutral0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: const Text('企業詳細'),
      ),
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: companyAsync.when(
        data: (company) {
          if (company == null) {
            return Center(
              child: Text(
                '企業が見つかりません',
                style: TextStylePalette.subText,
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(SpacePalette.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company['name'] ?? '企業名未設定',
                        style: TextStylePalette.lgListTitle,
                      ),
                      const SizedBox(height: SpacePalette.sm),
                      Text(
                        company['industry'] ?? '業種未設定',
                        style: TextStylePalette.subText,
                      ),

                      // 企業詳細画像
                      if (company['detail_image_url'] != null &&
                          (company['detail_image_url'] as String).isNotEmpty) ...[
                        const SizedBox(height: SpacePalette.base),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(RadiusPalette.lg),
                          child: Image.network(
                            company['detail_image_url'] as String,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],

                      const SizedBox(height: SpacePalette.base),
                      Text(
                        company['description'] ?? '説明未設定',
                        style: TextStylePalette.normalText,
                      ),
                      const SizedBox(height: SpacePalette.lg),
                      _buildSection(context, '動画', '/company/$companyId/videos'),
                      _buildSection(context, '求人', '/company/$companyId/jobs'),
                      _buildSection(
                          context, 'インターン', '/company/$companyId/interns'),

                      // HP・SNSリンク
                      _buildLinkRow(context, company),
                    ],
                  ),
                ),
              ],
            ),
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
            style: TextStylePalette.subText,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkRow(BuildContext context, Map<String, dynamic> company) {
    final website = company['website'] as String?;
    final snsUrl = company['sns_url'] as String?;

    return Row(
      children: [
        Expanded(
          child: _LinkButton(
            icon: Icons.language,
            label: 'HP',
            url: website,
          ),
        ),
        const SizedBox(width: SpacePalette.sm),
        Expanded(
          child: _LinkButton(
            icon: Icons.share,
            label: 'SNS',
            url: snsUrl,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacePalette.base),
      decoration: BoxDecoration(
        color: ColorPalette.neutral800,
        borderRadius: BorderRadius.circular(RadiusPalette.base),
        border: Border.all(color: ColorPalette.neutral600),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStylePalette.smListTitle,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: ColorPalette.neutral400,
        ),
        onTap: () => context.push(route),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? url;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return OutlinedButton.icon(
      onPressed: () async {
        if (!hasUrl) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$labelが設定されていません')),
          );
          return;
        }
        final uri = Uri.parse(url!.startsWith('http') ? url! : 'https://$url');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: hasUrl ? ColorPalette.primaryColor : ColorPalette.neutral400,
        side: BorderSide(
          color: hasUrl ? ColorPalette.primaryColor : ColorPalette.neutral600,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: SpacePalette.sm,
          horizontal: SpacePalette.base,
        ),
      ),
    );
  }
}
