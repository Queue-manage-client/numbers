// company_portal/intern/presentation/providers/company_intern_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/intern/data/repositories/company_intern_repository.dart';
import 'package:numbers/features/user/intern/domain/models/internship.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

final companyInternRepositoryProvider = Provider<CompanyInternRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CompanyInternRepository(supabase);
});

/// 企業のインターン一覧
final companyInternshipsProvider =
    FutureProvider<List<Internship>>((ref) async {
  final repository = ref.watch(companyInternRepositoryProvider);
  return await repository.getCompanyInternships();
});

/// 特定インターンの詳細
final companyInternshipProvider =
    FutureProvider.family<Internship?, String>((ref, internshipId) async {
  final repository = ref.watch(companyInternRepositoryProvider);
  return await repository.getInternship(internshipId);
});

/// 全申し込み一覧
final companyAllApplicationsProvider =
    FutureProvider<List<InternshipApplication>>((ref) async {
  final repository = ref.watch(companyInternRepositoryProvider);
  return await repository.getAllApplications();
});

/// 特定インターンの申し込み一覧
final internshipApplicationsProvider =
    FutureProvider.family<List<InternshipApplication>, String>(
        (ref, internshipId) async {
  final repository = ref.watch(companyInternRepositoryProvider);
  return await repository.getApplicationsForInternship(internshipId);
});

/// 申し込み数
final applicationCountsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, internshipId) async {
  final repository = ref.watch(companyInternRepositoryProvider);
  return await repository.getApplicationCounts(internshipId);
});

/// インターン操作用Notifier
class CompanyInternNotifier extends StateNotifier<AsyncValue<void>> {
  final CompanyInternRepository _repository;
  final Ref _ref;

  CompanyInternNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<Internship?> create({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('=== インターン投稿開始 ===');
      print('タイトル: $title');
      print('説明: $description');
      print('開始日: $startDate');
      print('終了日: $endDate');
      print('タグ: $tags');

      final internship = await _repository.createInternship(
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        tags: tags,
      );

      print('=== インターン投稿成功 ===');
      print('ID: ${internship.id}');

      state = const AsyncValue.data(null);
      _ref.invalidate(companyInternshipsProvider);
      return internship;
    } catch (e, st) {
      print('=== インターン投稿エラー ===');
      print('エラー: $e');
      print('スタックトレース: $st');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update({
    required String internshipId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isPublic,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateInternship(
        internshipId: internshipId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        tags: tags,
        isPublic: isPublic,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(companyInternshipsProvider);
      _ref.invalidate(companyInternshipProvider(internshipId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String internshipId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteInternship(internshipId);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyInternshipsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final companyInternNotifierProvider =
    StateNotifierProvider<CompanyInternNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(companyInternRepositoryProvider);
  return CompanyInternNotifier(repository, ref);
});

/// 申し込み管理用Notifier
class ApplicationManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final CompanyInternRepository _repository;
  final Ref _ref;

  ApplicationManagementNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> approve(String applicationId, String internshipId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveApplication(applicationId);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyAllApplicationsProvider);
      _ref.invalidate(internshipApplicationsProvider(internshipId));
      _ref.invalidate(applicationCountsProvider(internshipId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reject(
    String applicationId,
    String internshipId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectApplication(applicationId, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyAllApplicationsProvider);
      _ref.invalidate(internshipApplicationsProvider(internshipId));
      _ref.invalidate(applicationCountsProvider(internshipId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final applicationManagementNotifierProvider =
    StateNotifierProvider<ApplicationManagementNotifier, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(companyInternRepositoryProvider);
  return ApplicationManagementNotifier(repository, ref);
});
