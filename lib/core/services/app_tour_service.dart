// core/services/app_tour_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// アプリ操作ツアーのGlobalKeyを管理
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

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// ツアーを開始
  static void startTour(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      AppTourKeys.homeTab,
      AppTourKeys.searchTab,
      AppTourKeys.aiTab,
      AppTourKeys.chatTab,
      AppTourKeys.internTab,
    ]);
  }
}
