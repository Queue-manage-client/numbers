// company_portal/presentation/providers/company_portal_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/data/repositories/company_portal_repository.dart';

// Repository Provider
final companyPortalRepositoryProvider = Provider<CompanyPortalRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CompanyPortalRepository(supabase);
});

// 現在のユーザープロフィールProvider
final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

// 企業IDを取得するProvider
final currentCompanyIdProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?['company_id'] as String?,
    loading: () => null,
    error: (_, __) => null,
  );
});

// 企業情報Provider
final companyInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return null;

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCompanyById(companyId);
});

// ダッシュボード統計Provider
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return {'videos': 0, 'jobs': 0, 'internships': 0, 'chats': 0};

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getDashboardStats(companyId);
});

// 企業動画一覧Provider
final companyVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return [];

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCompanyVideos(companyId);
});

// 企業求人一覧Provider
final companyJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return [];

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCompanyJobs(companyId);
});

// 企業インターンシップ一覧Provider
final companyInternshipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return [];

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCompanyInternships(companyId);
});

// 企業チャットルーム一覧Provider
final companyChatRoomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return [];

  final repository = ref.watch(companyPortalRepositoryProvider);
  return await repository.getCompanyChatRooms(companyId);
});
