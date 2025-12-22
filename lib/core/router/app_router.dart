// core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:numbers/features/onboarding/presentation/pages/splash_page.dart';
import 'package:numbers/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:numbers/features/auth/presentation/pages/login_page.dart';
import 'package:numbers/features/auth/presentation/pages/signup_page.dart';
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
import 'package:numbers/features/user/job/presentation/pages/job_map_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_detail_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_application_confirm_page.dart';
import 'package:numbers/features/user/job/presentation/pages/job_application_complete_page.dart';
import 'package:numbers/features/user/intern/presentation/pages/intern_list_page.dart';
import 'package:numbers/features/user/intern/presentation/pages/intern_detail_page.dart';
import 'package:numbers/features/user/chat/presentation/pages/chat_list_page.dart';
import 'package:numbers/features/user/chat/presentation/pages/chat_room_page.dart';
import 'package:numbers/features/user/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/my_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/profile_edit_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_history_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/application_detail_page.dart';
import 'package:numbers/features/user/profile/presentation/pages/settings_page.dart';
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

final appRouter = GoRouter(
  initialLocation: '/',
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

    // User - Home & Feed
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedPage(),
    ),

    // User - Company
    GoRoute(
      path: '/company/:id',
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

    // User - Search
    GoRoute(
      path: '/search/videos',
      builder: (context, state) => const VideoSearchPage(),
    ),

    // User - Job
    GoRoute(
      path: '/jobs/map',
      builder: (context, state) => const JobMapPage(),
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

    // User - Intern
    GoRoute(
      path: '/interns',
      builder: (context, state) => const InternListPage(),
    ),
    GoRoute(
      path: '/interns/:id',
      builder: (context, state) => const InternDetailPage(),
    ),

    // User - Chat
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatListPage(),
    ),
    GoRoute(
      path: '/chats/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'] ?? '';
        return ChatRoomPage(roomId: roomId);
      },
    ),

    // User - AI Chat
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatPage(),
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
      path: '/applications',
      builder: (context, state) => const ApplicationHistoryPage(),
    ),
    GoRoute(
      path: '/applications/:id',
      builder: (context, state) => const ApplicationDetailPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
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
      builder: (context, state) => const CompanyInternEditPage(),
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
      path: '/company-portal/chats/:roomId', // ✅ パラメータ名を変更
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'] ?? ''; // ✅ roomIdを取得
        return CompanyChatRoomDetailPage(roomId: roomId); // ✅ roomIdを渡す
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
      builder: (context, state) => const AdminInquiryDetailPage(),
    ),
  ],
);