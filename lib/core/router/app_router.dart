// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:numbers/core/services/app_tour_service.dart';
import 'package:numbers/features/onboarding/presentation/pages/splash_page.dart';
import 'package:numbers/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:numbers/features/onboarding/presentation/pages/welcome_guide_page.dart';
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
import 'package:numbers/features/user/profile/presentation/pages/resume_builder_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_history_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_detail_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/settings_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/terms_of_service_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/privacy_policy_page.dart';
import 'package:numbers/features/auth/presentation/pages/company_login_page.dart';
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
import 'package:numbers/features/company_portal/profile/presentation/pages/company_terms_page.dart';
import 'package:numbers/features/company_portal/presentation/pages/company_approval_status_page.dart';
import 'package:numbers/features/company_portal/presentation/pages/company_portal_select_page.dart';
import 'package:numbers/features/company_portal/subscription/presentation/pages/plan_selection_page.dart';
import 'package:numbers/features/company_portal/subscription/presentation/pages/subscription_status_page.dart';
import 'package:numbers/features/company_portal/subscription/presentation/pages/plan_application_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_plan_application_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_login_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_user_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_video_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_job_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_intern_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_inquiry_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_inquiry_detail_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_feed_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_consent_management_page.dart';
import 'package:numbers/features/admin/presentation/pages/admin_company_approval_page.dart';
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

// ウェルカムガイド表示待ちフラグ（新規登録直後にtrueにセット）
bool pendingWelcomeGuide = false;

// 企業登録処理中フラグ（signUp後のauto redirectを抑制）
bool pendingCompanySignup = false;

// ロールキャッシュ（セッション中のDBクエリを削減）
String? _cachedRole;
String? _cachedUserId;
String? _cachedApprovalStatus;

void clearRoleCache() {
  _cachedRole = null;
  _cachedUserId = null;
  _cachedApprovalStatus = null;
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

      // ログイン済みユーザーが認証ページにアクセスした場合 → ロールに応じて遷移
      const authOnlyPaths = ['/login', '/signup', '/signup/individual', '/signup/company', '/onboarding'];
      if (isLoggedIn && authOnlyPaths.contains(currentPath)) {
        // 企業登録処理中はリダイレクトを抑制（signup関数が自分で遷移を制御する）
        if (pendingCompanySignup) {
          return null;
        }

        // 新規登録直後ならウェルカムガイドへ
        if (pendingWelcomeGuide) {
          pendingWelcomeGuide = false;
          return '/welcome-guide';
        }

        // ロールに応じた遷移先を決定
        try {
          final userId = supabase.auth.currentUser!.id;
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

          if (role == 'admin') return '/admin/dashboard';
          // company_userもユーザーと同じフィードに遷移
        } catch (_) {}

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
                  .select('role, company_id')
                  .eq('id', userId)
                  .maybeSingle();
              role = profile?['role'] as String?;
              _cachedUserId = userId;
              _cachedRole = role;

              // company_user の場合、企業の審査ステータスもキャッシュ
              if (role == 'company_user' && profile?['company_id'] != null) {
                try {
                  final company = await supabase
                      .from('companies')
                      .select('approval_status')
                      .eq('id', profile!['company_id'] as String)
                      .maybeSingle();
                  _cachedApprovalStatus = company?['approval_status'] as String? ?? 'pending';
                } catch (_) {
                  _cachedApprovalStatus = 'pending';
                }
              }
            }

            if (isAdminRoute && role != 'admin') {
              return '/feed';
            }
            if (isCompanyPortalRoute && role != 'company_user') {
              return '/feed';
            }

            // 企業ポータルへのアクセス時、未承認企業はステータスページへリダイレクト
            if (isCompanyPortalRoute && role == 'company_user') {
              final approvalStatus = _cachedApprovalStatus ?? 'pending';
              final isApprovalPage = currentPath == '/company-portal/approval-status';

              if (approvalStatus != 'approved' && !isApprovalPage) {
                return '/company-portal/approval-status';
              }
              if (approvalStatus == 'approved' && isApprovalPage) {
                return '/feed';
              }
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
        path: '/welcome-guide',
        builder: (context, state) => const WelcomeGuidePage(),
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
        pageBuilder: (context, state, navigationShell) {
          return NoTransitionPage(key: state.pageKey, child: ShowCaseWidget(
            onComplete: (_, __) => AppTourService.markTourSeen(),
            builder: (context) => _ShellWithTour(navigationShell: navigationShell),
          ));
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey, child: const FeedPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jobs/map',
                pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey, child: const JobMapPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-chat',
                pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey, child: const AiChatPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey, child: const _ChatBranchPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/interns',
                pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey, child: const _InternBranchPage()),
              ),
            ],
          ),
        ],
      ),

      // User - Company (/company/:id と /companies/:id の両方をサポート)
      GoRoute(
        path: '/company/:id',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyDetailPage()),
      ),
      GoRoute(
        path: '/companies/:id',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyDetailPage()),
      ),
      GoRoute(
        path: '/company/:id/videos',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyVideoListPage()),
      ),
      GoRoute(
        path: '/company/:id/jobs',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyJobListPage()),
      ),
      GoRoute(
        path: '/company/:id/interns',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyInternListPage()),
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
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const WatchHistoryPage()),
      ),

      // User - Search
      GoRoute(
        path: '/search/videos',
        builder: (context, state) => const VideoSearchPage(),
      ),

      GoRoute(
        path: '/jobs/:id',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const JobDetailPage()),
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
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const InternDetailPage()),
      ),

      GoRoute(
        path: '/chats/create',
        builder: (context, state) => const GroupChatCreatePage(),
      ),
      GoRoute(
        path: '/chats/:roomId',
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: ChatRoomPage(roomId: roomId));
        },
      ),


      // User - Profile
      GoRoute(
        path: '/my-page',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const MyPage()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ProfileEditPage()),
      ),
      GoRoute(
        path: '/resume',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ResumeViewPage()),
      ),
      GoRoute(
        path: '/resume/build',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ResumeBuilderPage()),
      ),
      GoRoute(
        path: '/applications',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ApplicationHistoryPage()),
      ),
      GoRoute(
        path: '/applications/:id',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: ApplicationDetailPage(
            applicationId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SettingsPage()),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const TermsOfServicePage()),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const PrivacyPolicyPage()),
      ),

      // Company Portal
      GoRoute(
        path: '/company-portal/login',
        builder: (context, state) => const CompanyLoginPage(),
      ),
      GoRoute(
        path: '/company-portal/approval-status',
        builder: (context, state) => const CompanyApprovalStatusPage(),
      ),
      GoRoute(
        path: '/company-portal/dashboard',
        redirect: (context, state) => '/feed',
      ),
      GoRoute(
        path: '/company-portal/select',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyPortalSelectPage()),
      ),
      GoRoute(
        path: '/company-portal/videos',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyVideoManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/videos/post',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyVideoPostPage()),
      ),
      GoRoute(
        path: '/company-portal/videos/list',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyVideoListManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/videos/:videoId/edit',
        pageBuilder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: CompanyVideoEditPage(videoId: videoId));
        },
      ),
      GoRoute(
        path: '/company-portal/jobs',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyJobManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/jobs/post',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyJobPostPage()),
      ),
      GoRoute(
        path: '/company-portal/jobs/list',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyJobListManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/jobs/:id/edit',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyJobEditPage()),
      ),
      GoRoute(
        path: '/company-portal/jobs/:id/applications',
        pageBuilder: (context, state) {
          final jobId = state.pathParameters['id'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: CompanyJobApplicationsPage(jobId: jobId));
        },
      ),
      GoRoute(
        path: '/company-portal/interns',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyInternManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/interns/post',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyInternPostPage()),
      ),
      GoRoute(
        path: '/company-portal/interns/list',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyInternListManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/interns/:id/edit',
        pageBuilder: (context, state) {
          final internshipId = state.pathParameters['id'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: CompanyInternEditPage(internshipId: internshipId));
        },
      ),
      GoRoute(
        path: '/company-portal/interns/:id/applications',
        pageBuilder: (context, state) {
          final internshipId = state.pathParameters['id'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: CompanyInternApplicationsPage(internshipId: internshipId));
        },
      ),
      GoRoute(
        path: '/company-portal/chats',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyChatManagementPage()),
      ),
      GoRoute(
        path: '/company-portal/chats/create',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyChatRoomCreatePage()),
      ),
      GoRoute(
        path: '/company-portal/chats/list',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyChatRoomListPage()),
      ),
      GoRoute(
        path: '/company-portal/chats/:roomId',
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return NoTransitionPage(key: state.pageKey, child: CompanyChatRoomDetailPage(roomId: roomId));
        },
      ),
      GoRoute(
        path: '/company-portal/profile/edit',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyProfileEditPage()),
      ),
      GoRoute(
        path: '/company-portal/subscription',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SubscriptionStatusPage()),
      ),
      GoRoute(
        path: '/company-portal/subscription/plans',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const PlanSelectionPage()),
      ),
      GoRoute(
        path: '/company-portal/subscription/applications',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const PlanApplicationPage()),
      ),
      GoRoute(
        path: '/company-portal/terms',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CompanyTermsPage()),
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
      GoRoute(
        path: '/admin/consents',
        builder: (context, state) => const AdminConsentManagementPage(),
      ),
      GoRoute(
        path: '/admin/company-approvals',
        builder: (context, state) => const AdminCompanyApprovalPage(),
      ),
      GoRoute(
        path: '/admin/plan-applications',
        builder: (context, state) => const AdminPlanApplicationPage(),
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

/// /chats ブランチのラッパ。企業ユーザー時はチャット管理を表示。
class _ChatBranchPage extends ConsumerWidget {
  const _ChatBranchPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'company_user') {
      return const CompanyChatManagementPage(inShell: true);
    }
    return const ChatListPage();
  }
}

/// /interns ブランチのラッパ。企業ユーザー時は管理メニューを表示。
class _InternBranchPage extends ConsumerWidget {
  const _InternBranchPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'company_user') {
      return const CompanyPortalSelectPage(inShell: true);
    }
    return const InternListPage();
  }
}
