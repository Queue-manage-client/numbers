// core/widgets/app_footer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

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
        top: SpacePalette.sm,
        bottom: bottomPadding > 0 ? bottomPadding : SpacePalette.sm,
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
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.search,
            activeIcon: Icons.search,
            label: '探す',
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            label: 'AI',
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            label: 'チャット',
            index: 3,
            isActive: currentIndex == 3,
          ),
          _buildNavItem(
            context,
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'インターン',
            index: 4,
            isActive: currentIndex == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
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
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? ColorPalette.primaryColor
                      : ColorPalette.neutral400,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? ColorPalette.primaryColor
                        : ColorPalette.neutral400,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
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
        top: SpacePalette.sm,
        bottom: bottomPadding > 0 ? bottomPadding : SpacePalette.sm,
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
          _buildNavItem(
            context,
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            label: 'AI',
            route: '/ai-chat',
            isActive: currentRoute == '/ai-chat',
          ),
          _buildNavItem(
            context,
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            label: 'チャット',
            route: '/chats',
            isActive: currentRoute == '/chats' || currentRoute.startsWith('/chats/'),
          ),
          _buildNavItem(
            context,
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'インターン',
            route: '/interns',
            isActive: currentRoute == '/interns' || currentRoute.startsWith('/interns/'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
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
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? ColorPalette.primaryColor
                      : ColorPalette.neutral400,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? ColorPalette.primaryColor
                        : ColorPalette.neutral400,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
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
