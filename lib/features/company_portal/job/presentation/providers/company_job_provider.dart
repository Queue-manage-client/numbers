// company_portal/job/presentation/providers/company_job_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numbers/features/auth/presentation/providers/auth_provider.dart';
import 'package:numbers/features/company_portal/job/data/repositories/company_job_repository.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';

final companyJobRepositoryProvider = Provider<CompanyJobRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CompanyJobRepository(supabase);
});

/// 企業の求人一覧
final companyJobListProvider =
    FutureProvider<List<Job>>((ref) async {
  final repository = ref.watch(companyJobRepositoryProvider);
  return await repository.getCompanyJobs();
});

/// 特定求人の詳細
final companyJobDetailProvider =
    FutureProvider.family<Job?, String>((ref, jobId) async {
  final repository = ref.watch(companyJobRepositoryProvider);
  return await repository.getJob(jobId);
});

/// 全申し込み一覧
final companyAllJobApplicationsProvider =
    FutureProvider<List<JobApplication>>((ref) async {
  final repository = ref.watch(companyJobRepositoryProvider);
  return await repository.getAllApplications();
});

/// 特定求人の申し込み一覧
final jobApplicationsForJobProvider =
    FutureProvider.family<List<JobApplication>, String>(
        (ref, jobId) async {
  final repository = ref.watch(companyJobRepositoryProvider);
  return await repository.getApplicationsForJob(jobId);
});

/// 申し込み数
final jobApplicationCountsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, jobId) async {
  final repository = ref.watch(companyJobRepositoryProvider);
  return await repository.getApplicationCounts(jobId);
});

/// 求人操作用Notifier
class CompanyJobNotifier extends StateNotifier<AsyncValue<void>> {
  final CompanyJobRepository _repository;
  final Ref _ref;

  CompanyJobNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<Job?> create({
    required String title,
    required String description,
    String? salary,
    String? location,
    String? jobType,
    String? jobCategory,
    String? workingHours,
    int? salaryMin,
    int? salaryMax,
    String status = 'open',
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('=== 求人投稿開始 ===');
      print('タイトル: $title');
      print('説明: $description');

      final job = await _repository.createJob(
        title: title,
        description: description,
        salary: salary,
        location: location,
        jobType: jobType,
        jobCategory: jobCategory,
        workingHours: workingHours,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        status: status,
        latitude: latitude,
        longitude: longitude,
      );

      print('=== 求人投稿成功 ===');
      print('ID: ${job.id}');

      state = const AsyncValue.data(null);
      _ref.invalidate(companyJobListProvider);
      return job;
    } catch (e, st) {
      print('=== 求人投稿エラー ===');
      print('エラー: $e');
      print('スタックトレース: $st');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update({
    required String jobId,
    String? title,
    String? description,
    String? salary,
    String? location,
    String? jobType,
    String? jobCategory,
    String? workingHours,
    int? salaryMin,
    int? salaryMax,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateJob(
        jobId: jobId,
        title: title,
        description: description,
        salary: salary,
        location: location,
        jobType: jobType,
        jobCategory: jobCategory,
        workingHours: workingHours,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        status: status,
        latitude: latitude,
        longitude: longitude,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(companyJobListProvider);
      _ref.invalidate(companyJobDetailProvider(jobId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String jobId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteJob(jobId);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyJobListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final companyJobNotifierProvider =
    StateNotifierProvider<CompanyJobNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(companyJobRepositoryProvider);
  return CompanyJobNotifier(repository, ref);
});

/// 求人申し込み管理用Notifier
class JobApplicationManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final CompanyJobRepository _repository;
  final Ref _ref;

  JobApplicationManagementNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> approve(String applicationId, String jobId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveApplication(applicationId);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyAllJobApplicationsProvider);
      _ref.invalidate(jobApplicationsForJobProvider(jobId));
      _ref.invalidate(jobApplicationCountsProvider(jobId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reject(
    String applicationId,
    String jobId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectApplication(applicationId, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(companyAllJobApplicationsProvider);
      _ref.invalidate(jobApplicationsForJobProvider(jobId));
      _ref.invalidate(jobApplicationCountsProvider(jobId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final jobApplicationManagementNotifierProvider =
    StateNotifierProvider<JobApplicationManagementNotifier, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(companyJobRepositoryProvider);
  return JobApplicationManagementNotifier(repository, ref);
});
