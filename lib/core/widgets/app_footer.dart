import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppFooter extends StatelessWidget {
  final String currentRoute;

  const AppFooter({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.only(top: 8, bottom: 4),
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
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'インターン/\nチャット',
                route: '/interns',
                isActive: currentRoute == '/interns' ||
                         currentRoute.startsWith('/interns/') ||
                         currentRoute == '/chats' ||
                         currentRoute.startsWith('/chats/'),
                isCenter: true,
              ),
              _buildNavItem(
                context,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'カレンダー',
                route: '/calendar',
                isActive: currentRoute == '/calendar',
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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCenter ? 0 : 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCenter) ...[
                  // 中央アイコンは大きく表示
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                ] else ...[
                  // 通常のアイコン
                  Icon(
                    isActive ? activeIcon : icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isCenter ? 8 : 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                  maxLines: 2,
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

