// admin/providers/admin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/admin/data/repositories/admin_repository.dart';

// ==========================================
// Repository Provider
// ==========================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AdminRepository(supabase);
});

// ==========================================
// 認証プロバイダー
// ==========================================

/// 現在のユーザーが管理者かどうか
final isAdminProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.isAdmin();
});

/// 管理者プロフィール
final adminProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

// ==========================================
// ダッシュボードプロバイダー
// ==========================================

final adminDashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getDashboardStats();
});

// ==========================================
// ユーザー管理プロバイダー
// ==========================================

class UserFilter {
  final String? role;
  final String? searchQuery;
  final int page;

  UserFilter({this.role, this.searchQuery, this.page = 0});

  UserFilter copyWith({String? role, String? searchQuery, int? page}) {
    return UserFilter(
      role: role ?? this.role,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }
}

final userFilterProvider = StateProvider<UserFilter>((ref) => UserFilter());

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(userFilterProvider);

  return await repository.getUsers(
    limit: 20,
    offset: filter.page * 20,
    roleFilter: filter.role,
    searchQuery: filter.searchQuery,
  );
});

final adminUserCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(userFilterProvider);

  return await repository.getUserCount(
    roleFilter: filter.role,
    searchQuery: filter.searchQuery,
  );
});

// ==========================================
// 動画管理プロバイダー
// ==========================================

class VideoFilter {
  final bool? isPublic;
  final String? companyId;
  final int page;

  VideoFilter({this.isPublic, this.companyId, this.page = 0});

  VideoFilter copyWith({bool? isPublic, String? companyId, int? page}) {
    return VideoFilter(
      isPublic: isPublic ?? this.isPublic,
      companyId: companyId ?? this.companyId,
      page: page ?? this.page,
    );
  }
}

final videoFilterProvider = StateProvider<VideoFilter>((ref) => VideoFilter());

final adminVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(videoFilterProvider);

  return await repository.getAllVideos(
    limit: 20,
    offset: filter.page * 20,
    isPublicFilter: filter.isPublic,
    companyId: filter.companyId,
  );
});

// ==========================================
// 求人管理プロバイダー
// ==========================================

class JobFilter {
  final String? status;
  final String? companyId;
  final int page;

  JobFilter({this.status, this.companyId, this.page = 0});

  JobFilter copyWith({String? status, String? companyId, int? page}) {
    return JobFilter(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      page: page ?? this.page,
    );
  }
}

final jobFilterProvider = StateProvider<JobFilter>((ref) => JobFilter());

final adminJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(jobFilterProvider);

  return await repository.getAllJobs(
    limit: 20,
    offset: filter.page * 20,
    statusFilter: filter.status,
    companyId: filter.companyId,
  );
});

// ==========================================
// インターン管理プロバイダー
// ==========================================

class InternFilter {
  final bool? isPublic;
  final String? companyId;
  final int page;

  InternFilter({this.isPublic, this.companyId, this.page = 0});

  InternFilter copyWith({bool? isPublic, String? companyId, int? page}) {
    return InternFilter(
      isPublic: isPublic ?? this.isPublic,
      companyId: companyId ?? this.companyId,
      page: page ?? this.page,
    );
  }
}

final internFilterProvider = StateProvider<InternFilter>((ref) => InternFilter());

final adminInternshipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(internFilterProvider);

  return await repository.getAllInternships(
    limit: 20,
    offset: filter.page * 20,
    isPublicFilter: filter.isPublic,
    companyId: filter.companyId,
  );
});

// ==========================================
// 問い合わせ管理プロバイダー
// ==========================================

class InquiryFilter {
  final String? status;
  final int page;

  InquiryFilter({this.status, this.page = 0});

  InquiryFilter copyWith({String? status, int? page}) {
    return InquiryFilter(
      status: status ?? this.status,
      page: page ?? this.page,
    );
  }
}

final inquiryFilterProvider = StateProvider<InquiryFilter>((ref) => InquiryFilter());

final adminInquiriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(inquiryFilterProvider);

  return await repository.getAllInquiries(
    limit: 20,
    offset: filter.page * 20,
    statusFilter: filter.status,
  );
});

final adminInquiryByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, inquiryId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getInquiryById(inquiryId);
});

// ==========================================
// 同意記録管理プロバイダー
// ==========================================

class ConsentFilter {
  final String? companyId;
  final String? agreementType;
  final int page;

  ConsentFilter({this.companyId, this.agreementType, this.page = 0});

  ConsentFilter copyWith({String? companyId, String? agreementType, int? page}) {
    return ConsentFilter(
      companyId: companyId ?? this.companyId,
      agreementType: agreementType ?? this.agreementType,
      page: page ?? this.page,
    );
  }
}

final consentFilterProvider = StateProvider<ConsentFilter>((ref) => ConsentFilter());

final adminConsentLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(consentFilterProvider);

  return await repository.getConsentLogs(
    limit: 20,
    offset: filter.page * 20,
    companyId: filter.companyId,
    agreementType: filter.agreementType,
  );
});

// ==========================================
// 企業一覧プロバイダー（フィルター用ドロップダウン）
// ==========================================

final adminCompaniesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getAllCompanies();
});
