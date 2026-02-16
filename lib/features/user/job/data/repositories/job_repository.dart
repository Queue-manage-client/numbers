// job/data/repositories/job_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

class JobRepository {
  final SupabaseClient _supabase;

  JobRepository(this._supabase);

  // ========== 求人一覧・詳細 ==========

  Future<List<Job>> getJobs() async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('status', 'open')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Job.fromJson(json)).toList();
  }

  Future<Job?> getJob(String jobId) async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', jobId)
        .maybeSingle();

    if (response == null) return null;
    return Job.fromJson(response);
  }

  // ========== 申し込み機能 ==========

  /// 求人に申し込む
  Future<JobApplication> applyJob({
    required String jobId,
    String? message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    final response = await _supabase
        .from('job_applications')
        .insert({
          'job_id': jobId,
          'user_id': userId,
          'status': 'applied',
          'message': message,
          'applied_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return JobApplication.fromJson(response);
  }

  /// 申し込みをキャンセル
  Future<void> cancelApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    await _supabase
        .from('job_applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId)
        .eq('user_id', userId)
        .eq('status', 'applied');
  }

  /// ユーザーの申し込み一覧を取得
  Future<List<JobApplication>> getApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    final response = await _supabase
        .from('job_applications')
        .select('*, jobs(*, companies(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => JobApplication.fromJson(json))
        .toList();
  }

  /// 特定求人の申し込み状態を確認
  Future<JobApplication?> getApplicationStatus(String jobId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final response = await _supabase
        .from('job_applications')
        .select()
        .eq('job_id', jobId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return JobApplication.fromJson(response);
  }

  /// 申し込み済みかどうかを確認
  Future<bool> hasApplied(String jobId) async {
    final application = await getApplicationStatus(jobId);
    return application != null &&
        application.status != ApplicationStatus.cancelled;
  }
}
