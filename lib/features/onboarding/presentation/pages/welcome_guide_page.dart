// onboarding/presentation/pages/welcome_guide_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

class WelcomeGuidePage extends StatelessWidget {
  const WelcomeGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ColorPalette.neutral900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ─── Hero セクション ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                        vertical: SpacePalette.lg * 2,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A1400),
                            ColorPalette.neutral900,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // ロゴ
                          ClipRRect(
                            borderRadius: BorderRadius.circular(RadiusPalette.lg),
                            child: Image.asset(
                              'assets/images/nbs_logo.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: SpacePalette.lg),
                          Text(
                            'ようこそ！',
                            style: TextStylePalette.header.copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: SpacePalette.sm),
                          Text(
                            'NBS~New Business Swipe~\nへの登録が完了しました',
                            textAlign: TextAlign.center,
                            style: TextStylePalette.subText.copyWith(
                              fontSize: FontSizePalette.size16,
                            ),
                          ),
                          const SizedBox(height: SpacePalette.lg),
                          // ゴールドのディバイダー
                          Container(
                            width: 60,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: ColorPalette.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── 使い方セクション ───
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacePalette.base,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'NBSでできること',
                            style: TextStylePalette.smHeader.copyWith(
                              color: ColorPalette.primaryColor,
                            ),
                          ),
                          const SizedBox(height: SpacePalette.lg * 1.5),

                          // Feature 1: 動画
                          _FeatureSection(
                            icon: Icons.play_circle_filled,
                            number: '01',
                            title: '動画で企業を知る',
                            description:
                                'ショート動画で企業の雰囲気や仕事内容をチェック。\nスワイプするだけで、気になる企業が見つかります。',
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: SpacePalette.lg * 1.5),

                          // Feature 2: マップ
                          _FeatureSection(
                            icon: Icons.map,
                            number: '02',
                            title: 'マップで求人を探す',
                            description:
                                '地図上で近くの求人をかんたん検索。\n通勤しやすい場所のお仕事が一目でわかります。',
                            screenWidth: screenWidth,
                            isReversed: true,
                          ),
                          const SizedBox(height: SpacePalette.lg * 1.5),

                          // Feature 3: AI
                          _FeatureSection(
                            icon: Icons.auto_awesome,
                            number: '03',
                            title: 'AIに相談する',
                            description:
                                '「どんな仕事が向いてる？」「面接のコツは？」\nAIがあなたの就活をサポートします。',
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: SpacePalette.lg * 1.5),

                          // Feature 4: チャット
                          _FeatureSection(
                            icon: Icons.chat_bubble,
                            number: '04',
                            title: '企業とチャット',
                            description:
                                '気になる企業に直接メッセージ。\n質問や応募もアプリ内で完結できます。',
                            screenWidth: screenWidth,
                            isReversed: true,
                          ),
                          const SizedBox(height: SpacePalette.lg * 1.5),

                          // Feature 5: インターン
                          _FeatureSection(
                            icon: Icons.school,
                            number: '05',
                            title: 'インターンを見つける',
                            description:
                                'インターンシップ情報も充実。\n実務経験を積んで、就活を有利に進めましょう。',
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: SpacePalette.lg * 2),

                          // ─── CTA セクション ───
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(SpacePalette.lg),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ColorPalette.primaryColor.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(RadiusPalette.lg),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ColorPalette.primaryColor.withOpacity(0.08),
                                  ColorPalette.neutral800,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'さっそく始めましょう！',
                                  style: TextStylePalette.smHeader,
                                ),
                                const SizedBox(height: SpacePalette.sm),
                                Text(
                                  'まずは動画を見て\n気になる企業を探してみてください',
                                  textAlign: TextAlign.center,
                                  style: TextStylePalette.subText,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: SpacePalette.lg),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 固定ボタン ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                SpacePalette.base,
                SpacePalette.sm,
                SpacePalette.base,
                SpacePalette.base,
              ),
              decoration: BoxDecoration(
                color: ColorPalette.neutral900,
                border: Border(
                  top: BorderSide(
                    color: ColorPalette.neutral600.withOpacity(0.5),
                  ),
                ),
              ),
              child: GradientButton(
                text: '始める',
                onPressed: () => context.go('/feed'),
                icon: const Icon(
                  Icons.arrow_forward,
                  color: ColorPalette.neutral900,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  final IconData icon;
  final String number;
  final String title;
  final String description;
  final double screenWidth;
  final bool isReversed;

  const _FeatureSection({
    required this.icon,
    required this.number,
    required this.title,
    required this.description,
    required this.screenWidth,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPalette.primaryColor.withOpacity(0.2),
            ColorPalette.primaryDark.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: ColorPalette.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        size: 32,
        color: ColorPalette.primaryColor,
      ),
    );

    final textWidget = Expanded(
      child: Column(
        crossAxisAlignment:
            isReversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStylePalette.smSubText.copyWith(
              color: ColorPalette.primaryColor.withOpacity(0.5),
              fontSize: FontSizePalette.size24,
              fontVariations: const [FontVariation('wght', 900)],
            ),
          ),
          const SizedBox(height: SpacePalette.xs),
          Text(
            title,
            style: TextStylePalette.smHeader,
            textAlign: isReversed ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: SpacePalette.sm),
          Text(
            description,
            style: TextStylePalette.subText,
            textAlign: isReversed ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isReversed
          ? [textWidget, const SizedBox(width: SpacePalette.base), iconWidget]
          : [iconWidget, const SizedBox(width: SpacePalette.base), textWidget],
    );
  }
}
