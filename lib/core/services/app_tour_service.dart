// core/services/app_tour_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
export 'package:tutorial_coach_mark/tutorial_coach_mark.dart' show ContentAlign;
import 'package:numbers/core/theme/app_theme.dart';

/// アプリ操作ツアーのGlobalKeyを管理（フッター用）
class AppTourKeys {
  static final homeTab = GlobalKey();
  static final searchTab = GlobalKey();
  static final aiTab = GlobalKey();
  static final chatTab = GlobalKey();
  static final internTab = GlobalKey();
}

/// ツアー表示済みかどうかを管理
class AppTourService {
  static const _key = 'has_seen_app_tour';
  static const _pageKeyPrefix = 'tour_seen_';

  // --- フッターツアー（showcaseview） ---

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static void startTour(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      AppTourKeys.homeTab,
      AppTourKeys.searchTab,
      AppTourKeys.aiTab,
      AppTourKeys.chatTab,
      AppTourKeys.internTab,
    ]);
  }

  // --- ページ別ツアー（tutorial_coach_mark） ---

  static Future<bool> hasSeenPageTour(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_pageKeyPrefix$pageKey') ?? false;
  }

  static Future<void> markPageTourSeen(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pageKeyPrefix$pageKey', true);
  }

  /// 全ツアーをリセット（フッター + 全ページ）
  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    final keys = prefs.getKeys().where((k) => k.startsWith(_pageKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// ページ別ツアーを表示するヘルパー
  /// 初回訪問時のみ自動表示し、完了時にフラグを保存する
  static Future<void> showPageTourIfNeeded({
    required BuildContext context,
    required String pageKey,
    required List<TargetFocus> targets,
  }) async {
    if (targets.isEmpty) return;
    final seen = await hasSeenPageTour(pageKey);
    if (seen) return;
    if (!context.mounted) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: 'スキップ',
      textStyleSkip: const TextStyle(
        fontFamily: 'NotoSansJP',
        fontSize: 14,
        fontVariations: [FontVariation('wght', 700)],
        color: Colors.white,
      ),
      paddingFocus: 10,
      onFinish: () => markPageTourSeen(pageKey),
      onSkip: () {
        markPageTourSeen(pageKey);
        return true;
      },
    ).show(context: context);
  }

  /// TargetFocus を簡単に作るヘルパー
  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    ContentAlign align = ContentAlign.bottom,
  }) {
    return TargetFocus(
      keyTarget: key,
      alignSkip: Alignment.bottomRight,
      shape: shape,
      radius: 8,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 18,
                    fontVariations: [FontVariation('wght', 800)],
                    color: ColorPalette.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 14,
                    fontVariations: [FontVariation('wght', 500)],
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
