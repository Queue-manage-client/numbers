// company_portal/data/repositories/company_portal_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyPortalRepository {
  final SupabaseClient _supabase;

  CompanyPortalRepository(this._supabase);

  /// 現在のユーザープロフィールを取得
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return null;
    }
  }

  /// 企業IDから企業情報を取得
  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('id', companyId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting company: $e');
      return null;
    }
  }

  /// 企業情報を更新
  Future<void> updateCompany(String companyId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('companies')
          .update(updateData)
          .eq('id', companyId);
    } catch (e) {
      debugPrint('Error updating company: $e');
      rethrow;
    }
  }

  /// ダッシュボード統計を取得
  Future<Map<String, int>> getDashboardStats(String companyId) async {
    try {
      // 全クエリを並列実行（N+1問題を回避）
      final results = await Future.wait([
        _supabase.from('company_videos').select().eq('company_id', companyId).count(),
        _supabase.from('jobs').select().eq('company_id', companyId).eq('status', 'open').count(),
        _supabase.from('internships').select().eq('company_id', companyId).eq('is_public', true).count(),
        _supabase.from('chat_rooms').select().eq('company_id', companyId).count(),
      ]);

      return {
        'videos': results[0].count,
        'jobs': results[1].count,
        'internships': results[2].count,
        'chats': results[3].count,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {'videos': 0, 'jobs': 0, 'internships': 0, 'chats': 0};
    }
  }

  // ==========================================
  // 動画関連
  // ==========================================

  /// 企業の動画一覧を取得
  Future<List<Map<String, dynamic>>> getCompanyVideos(String companyId) async {
    try {
      final response = await _supabase
          .from('company_videos')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error getting company videos: $e');
      return [];
    }
  }

  /// 動画IDから動画を取得
  Future<Map<String, dynamic>?> getVideoById(String videoId) async {
    try {
      final response = await _supabase
          .from('company_videos')
          .select()
          .eq('id', videoId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting video by id: $e');
      return null;
    }
  }

  /// 動画を作成
  Future<void> createVideo(Map<String, dynamic> videoData) async {
    try {
      await _supabase.from('company_videos').insert(videoData);
    } catch (e) {
      debugPrint('Error creating video: $e');
      rethrow;
    }
  }

  /// 動画を更新
  Future<void> updateVideo(String videoId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('company_videos')
          .update(updateData)
          .eq('id', videoId);
    } catch (e) {
      debugPrint('Error updating video: $e');
      rethrow;
    }
  }

  /// 動画を削除
  Future<void> deleteVideo(String videoId) async {
    try {
      // 動画データを取得（動画ファイルとサムネイルのパスを取得）
      final video = await getVideoById(videoId);
      
      if (video != null) {
        // Storageから動画ファイルを削除
        final videoPath = video['video_path'] as String?;
        if (videoPath != null && videoPath.isNotEmpty) {
          try {
            await _supabase.storage.from('company-videos').remove([videoPath]);
          } catch (e) {
            debugPrint('Error deleting video file: $e');
          }
        }

        // Storageからサムネイルを削除
        final thumbnailPath = video['thumbnail_path'] as String?;
        if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
          try {
            await _supabase.storage.from('company-thumbnails').remove([thumbnailPath]);
          } catch (e) {
            debugPrint('Error deleting thumbnail file: $e');
          }
        }
      }

      // データベースから動画レコードを削除
      await _supabase.from('company_videos').delete().eq('id', videoId);
    } catch (e) {
      debugPrint('Error deleting video: $e');
      rethrow;
    }
  }

  // ==========================================
  // 求人関連
  // ==========================================

  /// 企業の求人一覧を取得
  Future<List<Map<String, dynamic>>> getCompanyJobs(String companyId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error getting company jobs: $e');
      return [];
    }
  }

  /// 求人IDから求人を取得
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('id', jobId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting job by id: $e');
      return null;
    }
  }

  /// 求人を作成
  Future<void> createJob(Map<String, dynamic> jobData) async {
    try {
      await _supabase.from('jobs').insert(jobData);
    } catch (e) {
      debugPrint('Error creating job: $e');
      rethrow;
    }
  }

  /// 求人を更新
  Future<void> updateJob(String jobId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('jobs')
          .update(updateData)
          .eq('id', jobId);
    } catch (e) {
      debugPrint('Error updating job: $e');
      rethrow;
    }
  }

  /// 求人を削除
  Future<void> deleteJob(String jobId) async {
    try {
      await _supabase.from('jobs').delete().eq('id', jobId);
    } catch (e) {
      debugPrint('Error deleting job: $e');
      rethrow;
    }
  }

  // ==========================================
  // インターンシップ関連
  // ==========================================

  /// 企業のインターンシップ一覧を取得
  Future<List<Map<String, dynamic>>> getCompanyInternships(String companyId) async {
    try {
      final response = await _supabase
          .from('internships')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error getting company internships: $e');
      return [];
    }
  }

  /// インターンIDからインターンを取得
  Future<Map<String, dynamic>?> getInternshipById(String internshipId) async {
    try {
      final response = await _supabase
          .from('internships')
          .select()
          .eq('id', internshipId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error getting internship by id: $e');
      return null;
    }
  }

  /// インターンを作成
  Future<void> createInternship(Map<String, dynamic> internshipData) async {
    try {
      await _supabase.from('internships').insert(internshipData);
    } catch (e) {
      debugPrint('Error creating internship: $e');
      rethrow;
    }
  }

  /// インターンを更新
  Future<void> updateInternship(String internshipId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('internships')
          .update(updateData)
          .eq('id', internshipId);
    } catch (e) {
      debugPrint('Error updating internship: $e');
      rethrow;
    }
  }

  /// インターンを削除
  Future<void> deleteInternship(String internshipId) async {
    try {
      await _supabase.from('internships').delete().eq('id', internshipId);
    } catch (e) {
      debugPrint('Error deleting internship: $e');
      rethrow;
    }
  }

  // ==========================================
  // チャット関連
  // ==========================================

  /// 企業のチャットルーム一覧を取得
  Future<List<Map<String, dynamic>>> getCompanyChatRooms(String companyId) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select()
          .eq('company_id', companyId)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting company chat rooms: $e');
      return [];
    }
  }

  // ==========================================
  // 企業登録関連
  // ==========================================

  /// 企業を新規作成
  Future<String> createCompany(Map<String, dynamic> companyData) async {
    try {
      final response = await _supabase
          .from('companies')
          .insert(companyData)
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating company: $e');
      rethrow;
    }
  }

  /// ユーザープロフィールを更新（role と company_id を設定）
  Future<void> updateUserProfile({
    required String userId,
    String? role,
    String? companyId,
    String? position,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (role != null) updateData['role'] = role;
      if (companyId != null) updateData['company_id'] = companyId;
      if (position != null) updateData['position'] = position;
      
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}