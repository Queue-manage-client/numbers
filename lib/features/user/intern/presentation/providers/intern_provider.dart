// intern/presentation/providers/intern_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/intern/data/repositories/intern_repository.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

final internRepositoryProvider = Provider<InternRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InternRepository(supabase);
});

final internshipsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(internRepositoryProvider);
  final data = await repository.getInternships();
  return data;
});

final internshipProvider = FutureProvider.family<Map<String, dynamic>?, String>(
    (ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getInternship(internshipId);
});

// ========== 検索・フィルター関連プロバイダー ==========

/// 検索テキスト
final internSearchQueryProvider = StateProvider<String>((ref) => '');

/// 業種フィルター（null = 全て）
final internIndustryFilterProvider = StateProvider<String?>((ref) => null);

/// フィルタリング済みインターン一覧
final filteredInternshipsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final internshipsAsync = ref.watch(internshipsProvider);
  final query = ref.watch(internSearchQueryProvider).toLowerCase();
  final industry = ref.watch(internIndustryFilterProvider);

  return internshipsAsync.whenData((internships) {
    return internships.where((internship) {
      // テキスト検索
      if (query.isNotEmpty) {
        final title = (internship['title'] as String? ?? '').toLowerCase();
        final company = internship['companies'] as Map<String, dynamic>?;
        final companyName = (company?['name'] as String? ?? '').toLowerCase();
        if (!title.contains(query) && !companyName.contains(query)) {
          return false;
        }
      }

      // 業種フィルター
      if (industry != null) {
        final company = internship['companies'] as Map<String, dynamic>?;
        final companyIndustry = company?['industry'] as String?;
        if (companyIndustry != industry) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

// ========== 申し込み関連プロバイダー ==========

/// ユーザーの全申し込み一覧
final userApplicationsProvider =
    FutureProvider<List<InternshipApplication>>((ref) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getUserApplications();
});

/// 特定インターンの申し込み状態
final applicationStatusProvider =
    FutureProvider.family<InternshipApplication?, String>(
        (ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.getApplicationStatus(internshipId);
});

/// 申し込み済みかどうか
final hasAppliedProvider =
    FutureProvider.family<bool, String>((ref, internshipId) async {
  final repository = ref.watch(internRepositoryProvider);
  return await repository.hasApplied(internshipId);
});

/// 申し込み処理を行うNotifier
class InternApplicationNotifier extends StateNotifier<AsyncValue<void>> {
  final InternRepository _repository;
  final Ref _ref;

  InternApplicationNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> apply(String internshipId, {String? message}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.applyForInternship(
        internshipId: internshipId,
        message: message,
      );
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(userApplicationsProvider);
      _ref.invalidate(applicationStatusProvider(internshipId));
      _ref.invalidate(hasAppliedProvider(internshipId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancel(String applicationId, String internshipId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelApplication(applicationId);
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(userApplicationsProvider);
      _ref.invalidate(applicationStatusProvider(internshipId));
      _ref.invalidate(hasAppliedProvider(internshipId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final internApplicationNotifierProvider =
    StateNotifierProvider<InternApplicationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(internRepositoryProvider);
  return InternApplicationNotifier(repository, ref);
});
