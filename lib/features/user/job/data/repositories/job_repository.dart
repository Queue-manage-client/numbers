// job/data/repositories/job_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/job/domain/models/job.dart';
import 'package:numbers/features/user/job/domain/models/job_application.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

class JobRepository {
  final SupabaseClient _supabase;

  JobRepository(this._supabase);

  // ========== 求人一覧・詳細 ==========

  Future<List<Job>> getJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('id, company_id, title, description, salary, location_text, status, job_type, job_category, working_hours, salary_min, salary_max, latitude, longitude, thumbnail_url, created_at, updated_at, companies(*)')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Job.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Job?> getJob(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('id, company_id, title, description, salary, location_text, status, job_type, job_category, working_hours, salary_min, salary_max, latitude, longitude, thumbnail_url, created_at, updated_at, companies(*)')
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return Job.fromJson(response);
    } catch (e) {
      rethrow;
    }
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

    try {
      final response = await _supabase
          .from('job_applications')
          .insert({
            'job_id': jobId,
            'user_id': userId,
            'status': 'pending',
            'message': message,
            'applied_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return JobApplication.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込みをキャンセル
  Future<void> cancelApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      await _supabase
          .from('job_applications')
          .update({'status': 'cancelled'})
          .eq('id', applicationId)
          .eq('user_id', userId)
          .eq('status', 'pending');
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーの申し込み一覧を取得
  Future<List<JobApplication>> getApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      final response = await _supabase
          .from('job_applications')
          .select('*, jobs(id, company_id, title, description, salary, location_text, status, job_type, job_category, working_hours, salary_min, salary_max, latitude, longitude, thumbnail_url, created_at, updated_at, companies(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<JobApplication> results = [];
      for (final json in response as List) {
        try {
          final map = Map<String, dynamic>.from(json as Map);
          results.add(JobApplication.fromJson(map));
        } catch (e, st) {
          debugPrint('=== JobApplication parse error ===');
          debugPrint('Error: $e');
          debugPrint('Raw data: $json');
          debugPrint('Stack: $st');
        }
      }
      return results;
    } catch (e, st) {
      debugPrint('=== getApplications query error ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      rethrow;
    }
  }

  /// 特定求人の申し込み状態を確認
  Future<JobApplication?> getApplicationStatus(String jobId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    try {
      final response = await _supabase
          .from('job_applications')
          .select()
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return JobApplication.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込み済みかどうかを確認
  Future<bool> hasApplied(String jobId) async {
    try {
      final application = await getApplicationStatus(jobId);
      return application != null &&
          application.status != ApplicationStatus.cancelled;
    } catch (e) {
      rethrow;
    }
  }
}
