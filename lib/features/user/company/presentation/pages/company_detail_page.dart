// company/presentation/pages/company_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:numbers/features/user/company/presentation/providers/company_provider.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';

/// SNSプラットフォームの表示情報
const _snsPlatformInfo = <String, ({String label, IconData icon})>{
  'youtube': (label: 'YouTube', icon: Icons.play_circle_outline),
  'instagram': (label: 'Instagram', icon: Icons.camera_alt_outlined),
  'tiktok': (label: 'TikTok', icon: Icons.music_note_outlined),
  'facebook': (label: 'Facebook', icon: Icons.facebook),
  'linkedin': (label: 'LinkedIn', icon: Icons.business_center_outlined),
  'x': (label: 'X', icon: Icons.tag),
  'other': (label: 'SNS', icon: Icons.share),
};

class CompanyDetailPage extends ConsumerStatefulWidget {
  const CompanyDetailPage({super.key});

  @override
  ConsumerState<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends ConsumerState<CompanyDetailPage> {
  final _videoSectionKey = GlobalKey();
  final _jobSectionKey = GlobalKey();
  final _internSectionKey = GlobalKey();
  final _linkSectionKey = GlobalKey();
  bool _tourStarted = false;

  void _maybeStartTour() {
    if (_tourStarted) return;
    _tourStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppTourService.showPageTourIfNeeded(
        context: context,
        pageKey: 'company_detail',
        targets: [
          AppTourService.createTarget(
            key: _videoSectionKey,
            title: '動画',
            description: 'この企業が投稿した紹介動画を見ることができます。',
          ),
          AppTourService.createTarget(
            key: _jobSectionKey,
            title: '求人',
            description: 'この企業の求人情報を確認・応募できます。',
          ),
          AppTourService.createTarget(
            key: _internSectionKey,
            title: 'インターン',
            description: 'この企業のインターンシップ情報を確認できます。',
          ),
          AppTourService.createTarget(
            key: _linkSectionKey,
            title: 'HP・SNSリンク',
            description: '企業のホームページやSNSアカウントにアクセスできます。',
            align: ContentAlign.top,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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

          // データ読み込み後にツアー開始
          _maybeStartTour();

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
                      _buildSection(context, '動画', '/company/$companyId/videos', _videoSectionKey),
                      _buildSection(context, '求人', '/company/$companyId/jobs', _jobSectionKey),
                      _buildSection(
                          context, 'インターン', '/company/$companyId/interns', _internSectionKey),

                      // HP・SNSリンク（縦並び）
                      _buildLinkColumn(context, company),
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

  Widget _buildLinkColumn(BuildContext context, Map<String, dynamic> company) {
    final website = company['website'] as String?;

    // sns_links を取得
    final rawLinks = company['sns_links'];
    List<Map<String, dynamic>> snsLinks = [];
    if (rawLinks is List) {
      snsLinks = rawLinks
          .where((e) =>
              e is Map &&
              e['url'] != null &&
              (e['url'] as String).isNotEmpty)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return Column(
      key: _linkSectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HPボタン
        _LinkButton(
          icon: Icons.language,
          label: 'HP',
          url: website,
        ),
        // SNSボタン群
        ...snsLinks.map((link) {
          final platform = link['platform'] as String? ?? 'other';
          final url = link['url'] as String?;
          final info = _snsPlatformInfo[platform] ?? _snsPlatformInfo['other']!;
          return Padding(
            padding: const EdgeInsets.only(top: SpacePalette.sm),
            child: _LinkButton(
              icon: info.icon,
              label: info.label,
              url: url,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String route, GlobalKey sectionKey) {
    return Container(
      key: sectionKey,
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
