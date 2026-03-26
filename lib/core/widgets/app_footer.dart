// core/widgets/app_footer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:numbers/core/theme/app_theme.dart';
import 'package:numbers/core/services/app_tour_service.dart';

const _tourTitleStyle = TextStyle(
  fontFamily: 'NotoSansJP',
  fontSize: 16,
  fontVariations: [FontVariation('wght', 800)],
  color: ColorPalette.primaryColor,
);

const _tourDescStyle = TextStyle(
  fontFamily: 'NotoSansJP',
  fontSize: 14,
  fontVariations: [FontVariation('wght', 500)],
  color: Colors.white,
);

const _activeGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFFFE566), // 明るいゴールド
    Color(0xFFFFD700), // ゴールド
    Color(0xFFE6AC00), // 深いゴールド
  ],
);

/// Shell用フッター（StatefulShellRouteで使用、タブ切り替え時にリビルドしない）
class ShellFooter extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellFooter({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentIndex = navigationShell.currentIndex;

    return Container(
      color: ColorPalette.neutral900,
      padding: EdgeInsets.only(
        top: 0,
        bottom: bottomPadding > 0 ? bottomPadding : 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Showcase(
            key: AppTourKeys.homeTab,
            title: 'ホーム',
            description: '企業の動画フィードや特集をチェックできます。',
            titleTextStyle: _tourTitleStyle,
            descTextStyle: _tourDescStyle,
            tooltipBackgroundColor: const Color(0xFF3A3A3A),
            overlayOpacity: 0.7,
            child: _buildNavItem(
              context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'ホーム',
              index: 0,
              isActive: currentIndex == 0,
            ),
          ),
          Showcase(
            key: AppTourKeys.searchTab,
            title: '探す',
            description: 'マップで近くの求人やインターンを探せます。',
            titleTextStyle: _tourTitleStyle,
            descTextStyle: _tourDescStyle,
            tooltipBackgroundColor: const Color(0xFF3A3A3A),
            overlayOpacity: 0.7,
            child: _buildNavItem(
              context,
              icon: Icons.search,
              activeIcon: Icons.search,
              label: '探す',
              index: 1,
              isActive: currentIndex == 1,
            ),
          ),
          Showcase(
            key: AppTourKeys.aiTab,
            title: 'AI相談',
            description: 'AIに就活やインターンについて相談できます。',
            titleTextStyle: _tourTitleStyle,
            descTextStyle: _tourDescStyle,
            tooltipBackgroundColor: const Color(0xFF3A3A3A),
            overlayOpacity: 0.7,
            child: _buildImageNavItem(
              context,
              imagePath: 'assets/images/ai_button.png',
              label: 'AI',
              index: 2,
              isActive: currentIndex == 2,
            ),
          ),
          Showcase(
            key: AppTourKeys.chatTab,
            title: 'チャット',
            description: '企業とのDMやグループチャットができます。',
            titleTextStyle: _tourTitleStyle,
            descTextStyle: _tourDescStyle,
            tooltipBackgroundColor: const Color(0xFF3A3A3A),
            overlayOpacity: 0.7,
            child: _buildNavItem(
              context,
              imagePath: 'assets/images/8.png',
              label: 'チャット',
              index: 3,
              isActive: currentIndex == 3,
            ),
          ),
          Showcase(
            key: AppTourKeys.internTab,
            title: 'インターン',
            description: 'インターンを探して応募できます。',
            titleTextStyle: _tourTitleStyle,
            descTextStyle: _tourDescStyle,
            tooltipBackgroundColor: const Color(0xFF3A3A3A),
            overlayOpacity: 0.7,
            child: _buildNavItem(
              context,
              imagePath: 'assets/images/7.png',
              label: 'インターン',
              index: 4,
              isActive: currentIndex == 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageNavItem(
    BuildContext context, {
    required String imagePath,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isActive) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              }
            },
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    IconData? icon,
    IconData? activeIcon,
    String? imagePath,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            }
          },
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacePalette.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive)
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _activeGradient.createShader(bounds),
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          )
                        : Icon(
                            activeIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                  )
                else if (imagePath != null)
                  Image.asset(
                    imagePath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    color: ColorPalette.neutral400,
                  )
                else
                  Icon(
                    icon,
                    color: ColorPalette.neutral400,
                    size: 24,
                  ),
                const SizedBox(height: 2),
                if (isActive)
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _activeGradient.createShader(bounds),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: ColorPalette.neutral400,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 個別ページ用フッター（Shell外のページで使用）
class AppFooter extends StatelessWidget {
  final String currentRoute;

  const AppFooter({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: ColorPalette.neutral900,
      padding: EdgeInsets.only(
        top: 0,
        bottom: bottomPadding > 0 ? bottomPadding : 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'ホーム',
            route: '/feed',
            isActive: currentRoute == '/feed',
          ),
          _buildNavItem(
            context,
            icon: Icons.search,
            activeIcon: Icons.search,
            label: '探す',
            route: '/jobs/map',
            isActive: currentRoute == '/jobs/map' || currentRoute.startsWith('/jobs/'),
          ),
          _buildImageNavItem(
            context,
            imagePath: 'assets/images/ai_button.png',
            label: 'AI',
            route: '/ai-chat',
            isActive: currentRoute == '/ai-chat',
          ),
          _buildNavItem(
            context,
            imagePath: 'assets/images/8.png',
            label: 'チャット',
            route: '/chats',
            isActive: currentRoute == '/chats' || currentRoute.startsWith('/chats/'),
          ),
          _buildNavItem(
            context,
            imagePath: 'assets/images/7.png',
            label: 'インターン',
            route: '/interns',
            isActive: currentRoute == '/interns' || currentRoute.startsWith('/interns/'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageNavItem(
    BuildContext context, {
    required String imagePath,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (currentRoute != route) {
                context.go(route);
              }
            },
            borderRadius: BorderRadius.circular(RadiusPalette.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    IconData? icon,
    IconData? activeIcon,
    String? imagePath,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (currentRoute != route) {
              context.go(route);
            }
          },
          borderRadius: BorderRadius.circular(RadiusPalette.base),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacePalette.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive)
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _activeGradient.createShader(bounds),
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          )
                        : Icon(
                            activeIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                  )
                else if (imagePath != null)
                  Image.asset(
                    imagePath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    color: ColorPalette.neutral400,
                  )
                else
                  Icon(
                    icon,
                    color: ColorPalette.neutral400,
                    size: 24,
                  ),
                const SizedBox(height: 2),
                if (isActive)
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _activeGradient.createShader(bounds),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: ColorPalette.neutral400,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
