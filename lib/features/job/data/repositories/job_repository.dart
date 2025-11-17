import 'package:supabase_flutter/supabase_flutter.dart';

class JobRepository {
  final SupabaseClient _supabase;

  JobRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getJobs() async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('status', 'open')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getJob(String jobId) async {
    final response = await _supabase
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', jobId)
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getApplications(String userId) async {
    final response = await _supabase
        .from('job_applications')
        .select('*, jobs(*, companies(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> applyJob({
    required String jobId,
    required String userId,
  }) async {
    await _supabase.from('job_applications').insert({
      'job_id': jobId,
      'user_id': userId,
      'status': 'applied',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
