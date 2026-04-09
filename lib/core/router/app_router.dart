// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:numbers/core/services/app_tour_service.dart';
import 'package:numbers/features/onboarding/presentation/pages/splash_page.dart';
import 'package:numbers/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:numbers/features/auth/presentation/pages/login_page.dart';
import 'package:numbers/features/auth/presentation/pages/account_type_selection_page.dart';
import 'package:numbers/features/auth/presentation/pages/individual_signup_page.dart';
import 'package:numbers/features/auth/presentation/pages/company_signup_page.dart';
import 'package:numbers/features/auth/presentation/pages/password_reset_page.dart';
import 'package:numbers/features/user/feed/presentation/pages/feed_page.dart';
import 'package:numbers/features/user/company/presentation/pages/company_detail_page.dart';
import 'package:numbers/features/user/company/presentation/pages/company_video_list_page.dart';
import 'package:numbers/features/user/company/presentation/pages/company_job_list_page.dart';
import 'package:numbers/features/user/company/presentation/pages/company_intern_list_page.dart';
import 'package:numbers/features/user/search/presentation/pages/video_search_page.dart';
import 'package:numbers/features/user/feed/presentation/pages/video_detail_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_map_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_detail_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_application_confirm_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_application_complete_page.dart';
import 'package:numbers/features/user/intern/presentation/pages/intern_list_page.dart';
import 'package:numbers/features/user/intern/presentation/pages/intern_detail_page.dart';
import 'package:numbers/features/user/chat/presentation/pages/chat_list_page.dart';
import 'package:numbers/features/user/chat/presentation/pages/chat_room_page.dart';
import 'package:numbers/features/user/chat/presentation/pages/group_chat_create_page.dart';
import 'package:numbers/features/user/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/my_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/profile_edit_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/resume_view_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_history_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_detail_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/settings_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/terms_of_service_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/privacy_policy_page.dart';
import 'package:numbers/features/auth/presentation/pages/company_login_page.dart';
import 'package:numbers/features/company_portal/dashboard/presentation/pages/company_dashboard_page.dart';
import 'package:numbers/features/company_portal/video/presentation/pages/company_video_management_page.dart';
import 'package:numbers/features/company_portal/video/presentation/pages/company_video_post_page.dart';
import 'package:numbers/features/company_portal/video/presentation/pages/company_video_list_page.dart';
import 'package:numbers/features/company_portal/video/presentation/pages/company_video_edit_page.dart';
import 'package:numbers/features/company_portal/job/presentation/pages/company_job_management_page.dart';
import 'package:numbers/features/company_portal/job/presentation/pages/company_job_post_page.dart';
import 'package:numbers/features/company_portal/job/presentation/pages/company_job_list_page.dart';
import 'package:numbers/features/company_portal/job/presentation/pages/company_job_edit_page.dart';
import 'package:numbers/features/company_portal/intern/presentation/pages/company_intern_management_page.dart';
import 'package:numbers/features/company_portal/intern/presentation/pages/company_intern_post_page.dart';
import 'package:numbers/features/company_portal/intern/presentation/pages/company_intern_list_page.dart';
import 'package:numbers/features/company_portal/intern/presentation/pages/company_intern_edit_page.dart';
import 'package:numbers/features/company_portal/intern/presentation/pages/company_intern_applications_page.dart';
import 'package:numbers/features/company_portal/chat/presentation/pages/company_chat_management_page.dart';
import 'package:numbers/features/company_portal/chat/presentation/pages/company_chat_room_create_page.dart';
import 'package:numbers/features/company_portal/chat/presentation/pages/company_chat_room_list_page.dart';
import 'package:numbers/features/company_portal/chat/presentation/pages/company_chat_room_detail_page.dart';
import 'package:numbers/features/company_portal/profile/presentation/pages/company_profile_edit_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_login_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_user_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_video_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_job_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_intern_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_inquiry_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_inquiry_detail_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_feed_management_page.dart';
import 'package:numbers/features/company_portal/job/presentation/pages/company_job_applications_page.dart';
import 'package:numbers/core/widgets/app_footer.dart';
import 'package:numbers/features/user/feed/presentation/pages/feature_detail_page.dart';
import 'package:numbers/features/user/feed/presentation/pages/watch_history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';

/// 認証不要でアクセス可能なパス一覧
const _publicPaths = <String>[
  '/',
  '/onboarding',
  '/login',
  '/signup',
  '/signup/individual',
  '/signup/company',
  '/password-reset',
  '/company-portal/login',
  '/admin/login',
  '/terms',
  '/privacy',
];

// ロールキャッシュ（セッション中のDBクエリを削減）
String? _cachedRole;
String? _cachedUserId;

void clearRoleCache() {
  _cachedRole = null;
  _cachedUserId = null;
}

/// GoRouterインスタンスを生成する。
/// [authNotifier] をrefreshListenableとして渡すことで、
/// 認証状態変更時に自動でredirectが再評価される。
GoRouter createAppRouter(AuthNotifier authNotifier) {
  // 認証状態変更時にキャッシュをクリア
  authNotifier.addListener(clearRoleCache);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) async {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final currentPath = state.matchedLocation;

      // 公開パスかどうかを判定
      final isPublicPath = _publicPaths.contains(currentPath);

      // 未認証ユーザーが非公開パスにアクセスした場合 → /login へ
      if (!isLoggedIn && !isPublicPath) {
        return '/login';
      }

      // ログイン済みユーザーが認証ページにアクセスした場合 → /feed へ
      const authOnlyPaths = ['/login', '/signup', '/signup/individual', '/signup/company', '/onboarding'];
      if (isLoggedIn && authOnlyPaths.contains(currentPath)) {
        return '/feed';
      }

      // ロールベースのアクセス制御（admin, company_portal）
      if (isLoggedIn) {
        final isAdminRoute =
            currentPath.startsWith('/admin') && currentPath != '/admin/login';
        final isCompanyPortalRoute =
            currentPath.startsWith('/company-portal') &&
                currentPath != '/company-portal/login';

        if (isAdminRoute || isCompanyPortalRoute) {
          try {
            final userId = supabase.auth.currentUser!.id;

            // キャッシュが有効ならDBクエリをスキップ
            String? role;
            if (_cachedUserId == userId && _cachedRole != null) {
              role = _cachedRole;
            } else {
              final profile = await supabase
                  .from('profiles')
                  .select('role')
                  .eq('id', userId)
                  .maybeSingle();
              role = profile?['role'] as String?;
              _cachedUserId = userId;
              _cachedRole = role;
            }

            if (isAdminRoute && role != 'admin') {
              return '/feed';
            }
            if (isCompanyPortalRoute && role != 'company_user') {
              return '/feed';
            }
          } catch (e) {
            debugPrint('Router redirect: ロール取得エラー: $e');
            return '/feed';
          }
        }
      }

      // リダイレクト不要
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('ページが見つかりません')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '404 - お探しのページが見つかりませんでした',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Onboarding & Auth
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AccountTypeSelectionPage(),
      ),
      GoRoute(
        path: '/signup/individual',
        builder: (context, state) => const IndividualSignupPage(),
      ),
      GoRoute(
        path: '/signup/company',
        builder: (context, state) => const CompanySignupPage(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetPage(),
      ),

      // User - Main Tabs (persistent footer)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShowCaseWidget(
            onComplete: (_, __) => AppTourService.markTourSeen(),
            builder: (context) => _ShellWithTour(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jobs/map',
                builder: (context, state) => const JobMapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-chat',
                builder: (context, state) => const AiChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/interns',
                builder: (context, state) => const InternListPage(),
              ),
            ],
          ),
        ],
      ),

      // User - Company (/company/:id と /companies/:id の両方をサポート)
      GoRoute(
        path: '/company/:id',
        builder: (context, state) => const CompanyDetailPage(),
      ),
      GoRoute(
        path: '/companies/:id',
        builder: (context, state) => const CompanyDetailPage(),
      ),
      GoRoute(
        path: '/company/:id/videos',
        builder: (context, state) => const CompanyVideoListPage(),
      ),
      GoRoute(
        path: '/company/:id/jobs',
        builder: (context, state) => const CompanyJobListPage(),
      ),
      GoRoute(
        path: '/company/:id/interns',
        builder: (context, state) => const CompanyInternListPage(),
      ),

      // User - Video Detail (from feed)
      GoRoute(
        path: '/companies/:companyId/videos/:videoId',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final videoId = state.pathParameters['videoId'] ?? '';
          return VideoDetailPage(companyId: companyId, videoId: videoId);
        },
      ),

      // User - Feature Detail
      GoRoute(
        path: '/feature/:id',
        builder: (context, state) {
          final slide = state.extra;
          if (slide is! SlideData) {
            // state.extraがnullまたは型不一致の場合、フィードにリダイレクト
            return const FeedPage();
          }
          return FeatureDetailPage(slide: slide);
        },
      ),

      // User - Watch History
      GoRoute(
        path: '/watch-history',
        builder: (context, state) => const WatchHistoryPage(),
      ),

      // User - Search
      GoRoute(
        path: '/search/videos',
        builder: (context, state) => const VideoSearchPage(),
      ),

      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) => const JobDetailPage(),
      ),
      GoRoute(
        path: '/jobs/:id/apply/confirm',
        builder: (context, state) => const JobApplicationConfirmPage(),
      ),
      GoRoute(
        path: '/jobs/:id/apply/complete',
        builder: (context, state) => const JobApplicationCompletePage(),
      ),

      GoRoute(
        path: '/interns/:id',
        builder: (context, state) => const InternDetailPage(),
      ),

      GoRoute(
        path: '/chats/create',
        builder: (context, state) => const GroupChatCreatePage(),
      ),
      GoRoute(
        path: '/chats/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return ChatRoomPage(roomId: roomId);
        },
      ),


      // User - Profile
      GoRoute(
        path: '/my-page',
        builder: (context, state) => const MyPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: '/resume',
        builder: (context, state) => const ResumeViewPage(),
      ),
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationHistoryPage(),
      ),
      GoRoute(
        path: '/applications/:id',
        builder: (context, state) => ApplicationDetailPage(
          applicationId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      // Company Portal
      GoRoute(
        path: '/company-portal/login',
        builder: (context, state) => const CompanyLoginPage(),
      ),
      GoRoute(
        path: '/company-portal/dashboard',
        builder: (context, state) => const CompanyDashboardPage(),
      ),
      GoRoute(
        path: '/company-portal/videos',
        builder: (context, state) => const CompanyVideoManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/videos/post',
        builder: (context, state) => const CompanyVideoPostPage(),
      ),
      GoRoute(
        path: '/company-portal/videos/list',
        builder: (context, state) => const CompanyVideoListManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/videos/:videoId/edit',
        builder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          return CompanyVideoEditPage(videoId: videoId);
        },
      ),
      GoRoute(
        path: '/company-portal/jobs',
        builder: (context, state) => const CompanyJobManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/jobs/post',
        builder: (context, state) => const CompanyJobPostPage(),
      ),
      GoRoute(
        path: '/company-portal/jobs/list',
        builder: (context, state) => const CompanyJobListManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/jobs/:id/edit',
        builder: (context, state) => const CompanyJobEditPage(),
      ),
      GoRoute(
        path: '/company-portal/jobs/:id/applications',
        builder: (context, state) {
          final jobId = state.pathParameters['id'] ?? '';
          return CompanyJobApplicationsPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/company-portal/interns',
        builder: (context, state) => const CompanyInternManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/interns/post',
        builder: (context, state) => const CompanyInternPostPage(),
      ),
      GoRoute(
        path: '/company-portal/interns/list',
        builder: (context, state) => const CompanyInternListManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/interns/:id/edit',
        builder: (context, state) {
          final internshipId = state.pathParameters['id'] ?? '';
          return CompanyInternEditPage(internshipId: internshipId);
        },
      ),
      GoRoute(
        path: '/company-portal/interns/:id/applications',
        builder: (context, state) {
          final internshipId = state.pathParameters['id'] ?? '';
          return CompanyInternApplicationsPage(internshipId: internshipId);
        },
      ),
      GoRoute(
        path: '/company-portal/chats',
        builder: (context, state) => const CompanyChatManagementPage(),
      ),
      GoRoute(
        path: '/company-portal/chats/create',
        builder: (context, state) => const CompanyChatRoomCreatePage(),
      ),
      GoRoute(
        path: '/company-portal/chats/list',
        builder: (context, state) => const CompanyChatRoomListPage(),
      ),
      GoRoute(
        path: '/company-portal/chats/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return CompanyChatRoomDetailPage(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/company-portal/profile/edit',
        builder: (context, state) => const CompanyProfileEditPage(),
      ),

      // Admin
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUserManagementPage(),
      ),
      GoRoute(
        path: '/admin/videos',
        builder: (context, state) => const AdminVideoManagementPage(),
      ),
      GoRoute(
        path: '/admin/jobs',
        builder: (context, state) => const AdminJobManagementPage(),
      ),
      GoRoute(
        path: '/admin/interns',
        builder: (context, state) => const AdminInternManagementPage(),
      ),
      GoRoute(
        path: '/admin/inquiries',
        builder: (context, state) => const AdminInquiryManagementPage(),
      ),
      GoRoute(
        path: '/admin/inquiries/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdminInquiryDetailPage(inquiryId: id);
        },
      ),
      GoRoute(
        path: '/admin/feed',
        builder: (context, state) => const AdminFeedManagementPage(),
      ),
    ],
  );
}

/// ShowCaseWidget内で使用するShell（初回ツアー自動開始）
class _ShellWithTour extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellWithTour({required this.navigationShell});

  @override
  State<_ShellWithTour> createState() => _ShellWithTourState();
}

class _ShellWithTourState extends State<_ShellWithTour> {
  bool _tourChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tourChecked) {
      _tourChecked = true;
      _checkAndStartTour();
    }
  }

  Future<void> _checkAndStartTour() async {
    final hasSeen = await AppTourService.hasSeenTour();
    if (!hasSeen && mounted) {
      // フレーム描画後にツアー開始
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppTourService.startTour(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: ShellFooter(navigationShell: widget.navigationShell),
    );
  }
}
