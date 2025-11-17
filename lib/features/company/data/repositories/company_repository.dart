import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyRepository {
  final SupabaseClient _supabase;

  CompanyRepository(this._supabase);

  Future<Map<String, dynamic>?> getCompany(String companyId) async {
    final response = await _supabase
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getCompanyVideos(String companyId) async {
    final response = await _supabase
        .from('company_videos')
        .select()
        .eq('company_id', companyId)
        .eq('is_public', true)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCompanyJobs(String companyId) async {
    final response = await _supabase
        .from('jobs')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'open')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCompanyInternships(
      String companyId) async {
    final response = await _supabase
        .from('internships')
        .select()
        .eq('company_id', companyId)
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // フィード用：全企業の公開動画を取得
  Future<List<Map<String, dynamic>>> getAllPublicVideos() async {
    final response = await _supabase
        .from('company_videos')
        .select('*, companies(*)')
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
