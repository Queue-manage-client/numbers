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
          height: 65,
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'インターン',
                route: '/interns',
                isActive: currentRoute == '/interns' || currentRoute.startsWith('/interns/'),
              ),
              _buildNavItem(
                context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'チャット',
                route: '/chats',
                isActive: currentRoute == '/chats' || currentRoute.startsWith('/chats/'),
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
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
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

