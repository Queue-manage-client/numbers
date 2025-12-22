// core/widgets/app_footer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  final String currentRoute;

  const AppFooter({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.neutral0,
        border: Border(
          top: BorderSide(
            color: ColorPalette.neutral200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.only(
            top: SpacePalette.sm,
            bottom: SpacePalette.xs,
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
                isCenter: false,
              ),
              _buildNavItem(
                context,
                icon: Icons.search,
                activeIcon: Icons.search,
                label: '探す',
                route: '/jobs/map',
                isActive: currentRoute == '/jobs/map' || currentRoute.startsWith('/jobs/'),
                isCenter: false,
              ),
              _buildNavItem(
                context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'チャット',
                route: '/chats',
                isActive: currentRoute == '/chats' || currentRoute.startsWith('/chats/'),
                isCenter: true,
              ),
              _buildNavItem(
                context,
                icon: Icons.school_outlined,
                activeIcon: Icons.school,
                label: 'インターン',
                route: '/interns',
                isActive: currentRoute == '/interns' || currentRoute.startsWith('/interns/'),
                isCenter: false,
              ),
              _buildNavItem(
                context,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'その他',
                route: '/my-page',
                isActive: currentRoute == '/my-page' ||
                         currentRoute == '/profile/edit' ||
                         currentRoute == '/applications' ||
                         currentRoute.startsWith('/applications/') ||
                         currentRoute == '/settings',
                isCenter: false,
              ),
            ],
          ),
        ),
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
    required bool isCenter,
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
            padding: EdgeInsets.symmetric(
              vertical: isCenter ? 0 : SpacePalette.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCenter) ...[
                  // 中央アイコンは大きく表示
                  Container(
                    padding: const EdgeInsets.all(SpacePalette.sm),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive
                          ? ColorPalette.primaryColor
                          : ColorPalette.neutral500,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                ] else ...[
                  // 通常のアイコン
                  Icon(
                    isActive ? activeIcon : icon,
                    color: isActive
                        ? ColorPalette.primaryColor
                        : ColorPalette.neutral500,
                    size: 24,
                  ),
                  const SizedBox(height: SpacePalette.xs),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isCenter ? 9 : 9,
                    color: isActive
                        ? ColorPalette.primaryColor
                        : ColorPalette.neutral500,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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