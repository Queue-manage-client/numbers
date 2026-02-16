// job/presentation/providers/job_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/user/job/data/repositories/job_repository.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobRepository(supabase);
});

final jobsProvider = FutureProvider<List<Job>>((ref) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getJobs();
});

final jobProvider = FutureProvider.family<Job?, String>((ref, jobId) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getJob(jobId);
});

// ========== 申し込み関連プロバイダー ==========

/// ユーザーの全求人申し込み一覧
final jobApplicationsProvider =
    FutureProvider<List<JobApplication>>((ref) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getApplications();
});

/// 特定求人の申し込み状態
final jobApplicationStatusProvider =
    FutureProvider.family<JobApplication?, String>((ref, jobId) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.getApplicationStatus(jobId);
});

/// 申し込み済みかどうか
final hasAppliedToJobProvider =
    FutureProvider.family<bool, String>((ref, jobId) async {
  final repository = ref.watch(jobRepositoryProvider);
  return await repository.hasApplied(jobId);
});

/// 申し込み処理を行うNotifier
class JobApplicationNotifier extends StateNotifier<AsyncValue<void>> {
  final JobRepository _repository;
  final Ref _ref;

  JobApplicationNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> apply(String jobId, {String? message}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.applyJob(
        jobId: jobId,
        message: message,
      );
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(jobApplicationsProvider);
      _ref.invalidate(jobApplicationStatusProvider(jobId));
      _ref.invalidate(hasAppliedToJobProvider(jobId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancel(String applicationId, String jobId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelApplication(applicationId);
      state = const AsyncValue.data(null);

      // 関連するプロバイダーを更新
      _ref.invalidate(jobApplicationsProvider);
      _ref.invalidate(jobApplicationStatusProvider(jobId));
      _ref.invalidate(hasAppliedToJobProvider(jobId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final jobApplicationNotifierProvider =
    StateNotifierProvider<JobApplicationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(jobRepositoryProvider);
  return JobApplicationNotifier(repository, ref);
});
