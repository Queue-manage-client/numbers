import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyPortalRepository {
  final SupabaseClient _supabase;

  CompanyPortalRepository(this._supabase);

  // 現在のユーザーのプロフィールを取得
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('*, companies(*)')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  // 企業情報を取得
  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    final response = await _supabase
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    return response;
  }

  // 企業情報を更新
  Future<void> updateCompany(String companyId, Map<String, dynamic> data) async {
    await _supabase
        .from('companies')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', companyId);
  }

  // 企業の動画を取得
  Future<List<Map<String, dynamic>>> getCompanyVideos(String companyId) async {
    final response = await _supabase
        .from('company_videos')
        .select()
        .eq('company_id', companyId)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 動画を投稿
  Future<Map<String, dynamic>> createVideo(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('company_videos')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // 動画を更新
  Future<void> updateVideo(String videoId, Map<String, dynamic> data) async {
    await _supabase
        .from('company_videos')
        .update(data)
        .eq('id', videoId);
  }

  // 動画を削除
  Future<void> deleteVideo(String videoId) async {
    await _supabase
        .from('company_videos')
        .delete()
        .eq('id', videoId);
  }

  // 企業の求人を取得
  Future<List<Map<String, dynamic>>> getCompanyJobs(String companyId) async {
    final response = await _supabase
        .from('jobs')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 求人を投稿
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('jobs')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // 求人を更新
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _supabase
        .from('jobs')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', jobId);
  }

  // 求人を削除
  Future<void> deleteJob(String jobId) async {
    await _supabase
        .from('jobs')
        .delete()
        .eq('id', jobId);
  }

  // 企業のインターンシップを取得
  Future<List<Map<String, dynamic>>> getCompanyInternships(String companyId) async {
    final response = await _supabase
        .from('internships')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // インターンシップを投稿
  Future<Map<String, dynamic>> createInternship(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('internships')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // インターンシップを更新
  Future<void> updateInternship(String internshipId, Map<String, dynamic> data) async {
    await _supabase
        .from('internships')
        .update(data)
        .eq('id', internshipId);
  }

  // インターンシップを削除
  Future<void> deleteInternship(String internshipId) async {
    await _supabase
        .from('internships')
        .delete()
        .eq('id', internshipId);
  }

  // 企業のチャットルームを取得
  Future<List<Map<String, dynamic>>> getCompanyChatRooms(String companyId) async {
    final response = await _supabase
        .from('chat_rooms')
        .select('*, chat_messages(count)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // チャットルームを作成
  Future<Map<String, dynamic>> createChatRoom(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('chat_rooms')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // ダッシュボード統計データを取得
  Future<Map<String, int>> getDashboardStats(String companyId) async {
    final videos = await _supabase
        .from('company_videos')
        .select('id')
        .eq('company_id', companyId);

    final jobs = await _supabase
        .from('jobs')
        .select('id')
        .eq('company_id', companyId);

    final internships = await _supabase
        .from('internships')
        .select('id')
        .eq('company_id', companyId);

    final chatRooms = await _supabase
        .from('chat_rooms')
        .select('id')
        .eq('company_id', companyId);

    return {
      'videos': (videos as List).length,
      'jobs': (jobs as List).length,
      'internships': (internships as List).length,
      'chats': (chatRooms as List).length,
    };
  }
}
