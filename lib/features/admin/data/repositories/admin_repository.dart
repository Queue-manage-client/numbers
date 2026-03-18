// admin/data/repositories/admin_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // ==========================================
  // 認証・認可
  // ==========================================

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
      // Error getting current user profile
      return null;
    }
  }

  /// 現在のユーザーが管理者かどうかを確認
  Future<bool> isAdmin() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['role'] == 'admin';
    } catch (e) {
      // Error checking admin status
      return false;
    }
  }

  // ==========================================
  // ダッシュボード統計
  // ==========================================

  /// ダッシュボード用の統計情報を取得
  Future<Map<String, int>> getDashboardStats() async {
    // 各クエリを独立して実行（1つの失敗が他に影響しない）
    Future<int> countTable(String table, {Map<String, dynamic>? filter}) async {
      try {
        var query = _supabase.from(table).select();
        if (filter != null) {
          for (final entry in filter.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }
        final response = await query.count();
        return response.count;
      } catch (e) {
        return 0;
      }
    }

    final results = await Future.wait([
      countTable('profiles'),
      countTable('companies'),
      countTable('company_videos'),
      countTable('jobs', filter: {'status': 'open'}),
      countTable('internships', filter: {'is_public': true}),
      countTable('inquiries', filter: {'status': 'open'}),
    ]);

    return {
      'users': results[0],
      'companies': results[1],
      'videos': results[2],
      'jobs': results[3],
      'internships': results[4],
      'openInquiries': results[5],
    };
  }

  // ==========================================
  // ユーザー管理
  // ==========================================

  /// ユーザー一覧を取得
  Future<List<Map<String, dynamic>>> getUsers({
    int limit = 20,
    int offset = 0,
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from('profiles').select('*, companies(name)');

      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('nickname', '%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting users
      return [];
    }
  }

  /// ユーザー数を取得（ページネーション用）
  Future<int> getUserCount({
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from('profiles').select();

      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('nickname', '%$searchQuery%');
      }

      final response = await query.count();
      return response.count;
    } catch (e) {
      // Error getting user count
      return 0;
    }
  }

  /// ユーザー情報を更新
  Future<void> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      // Error updating user
      rethrow;
    }
  }

  /// ユーザーを停止
  Future<void> suspendUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_suspended': true})
          .eq('id', userId);
    } catch (e) {
      // Error suspending user
      rethrow;
    }
  }

  /// ユーザーを復活
  Future<void> reactivateUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_suspended': false})
          .eq('id', userId);
    } catch (e) {
      // Error reactivating user
      rethrow;
    }
  }

  // ==========================================
  // 動画管理
  // ==========================================

  /// 全動画一覧を取得
  Future<List<Map<String, dynamic>>> getAllVideos({
    int limit = 20,
    int offset = 0,
    bool? isPublicFilter,
    String? companyId,
  }) async {
    try {
      var query = _supabase.from('company_videos').select('*, companies(id, name)');

      if (isPublicFilter != null) {
        query = query.eq('is_public', isPublicFilter);
      }

      if (companyId != null && companyId.isNotEmpty) {
        query = query.eq('company_id', companyId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting all videos
      return [];
    }
  }

  /// 動画の公開状態を更新
  Future<void> updateVideoVisibility(String videoId, bool isPublic) async {
    try {
      await _supabase
          .from('company_videos')
          .update({'is_public': isPublic})
          .eq('id', videoId);
    } catch (e) {
      // Error updating video visibility
      rethrow;
    }
  }

  /// 動画を削除
  Future<void> deleteVideo(String videoId) async {
    try {
      // 動画データを取得
      final video = await _supabase
          .from('company_videos')
          .select()
          .eq('id', videoId)
          .maybeSingle();

      if (video != null) {
        // Storageから動画ファイルを削除
        final videoPath = video['video_path'] as String?;
        if (videoPath != null && videoPath.isNotEmpty && videoPath != 'placeholder_path') {
          try {
            await _supabase.storage.from('company-videos').remove([videoPath]);
          } catch (e) {
            // Error deleting video file
          }
        }

        // Storageからサムネイルを削除
        final thumbnailPath = video['thumbnail_path'] as String?;
        if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
          try {
            await _supabase.storage.from('company-thumbnails').remove([thumbnailPath]);
          } catch (e) {
            // Error deleting thumbnail file
          }
        }
      }

      // データベースから動画レコードを削除
      await _supabase.from('company_videos').delete().eq('id', videoId);
    } catch (e) {
      // Error deleting video
      rethrow;
    }
  }

  // ==========================================
  // 求人管理
  // ==========================================

  /// 全求人一覧を取得
  Future<List<Map<String, dynamic>>> getAllJobs({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? companyId,
  }) async {
    try {
      var query = _supabase.from('jobs').select('*, companies(id, name)');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      if (companyId != null && companyId.isNotEmpty) {
        query = query.eq('company_id', companyId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting all jobs
      return [];
    }
  }

  /// 求人のステータスを更新
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _supabase
          .from('jobs')
          .update({'status': status})
          .eq('id', jobId);
    } catch (e) {
      // Error updating job status
      rethrow;
    }
  }

  /// 求人を削除
  Future<void> deleteJob(String jobId) async {
    try {
      await _supabase.from('jobs').delete().eq('id', jobId);
    } catch (e) {
      // Error deleting job
      rethrow;
    }
  }

  // ==========================================
  // インターン管理
  // ==========================================

  /// 全インターン一覧を取得
  Future<List<Map<String, dynamic>>> getAllInternships({
    int limit = 20,
    int offset = 0,
    bool? isPublicFilter,
    String? companyId,
  }) async {
    try {
      var query = _supabase.from('internships').select('*, companies(id, name)');

      if (isPublicFilter != null) {
        query = query.eq('is_public', isPublicFilter);
      }

      if (companyId != null && companyId.isNotEmpty) {
        query = query.eq('company_id', companyId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting all internships
      return [];
    }
  }

  /// インターンの公開状態を更新
  Future<void> updateInternshipVisibility(String internshipId, bool isPublic) async {
    try {
      await _supabase
          .from('internships')
          .update({'is_public': isPublic})
          .eq('id', internshipId);
    } catch (e) {
      // Error updating internship visibility
      rethrow;
    }
  }

  /// インターンを削除
  Future<void> deleteInternship(String internshipId) async {
    try {
      await _supabase.from('internships').delete().eq('id', internshipId);
    } catch (e) {
      // Error deleting internship
      rethrow;
    }
  }

  // ==========================================
  // 問い合わせ管理
  // ==========================================

  /// 全問い合わせ一覧を取得
  Future<List<Map<String, dynamic>>> getAllInquiries({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
  }) async {
    try {
      var query = _supabase.from('inquiries').select('*, profiles(id, nickname)');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting all inquiries
      return [];
    }
  }

  /// 問い合わせ詳細を取得
  Future<Map<String, dynamic>?> getInquiryById(String inquiryId) async {
    try {
      final response = await _supabase
          .from('inquiries')
          .select('*, profiles(id, nickname)')
          .eq('id', inquiryId)
          .maybeSingle();

      return response;
    } catch (e) {
      // Error getting inquiry by id
      return null;
    }
  }

  /// 問い合わせのステータスを更新
  Future<void> updateInquiryStatus(String inquiryId, String status) async {
    try {
      await _supabase
          .from('inquiries')
          .update({'status': status})
          .eq('id', inquiryId);
    } catch (e) {
      // Error updating inquiry status
      rethrow;
    }
  }

  // ==========================================
  // 企業一覧（フィルター用）
  // ==========================================

  /// 全企業一覧を取得
  Future<List<Map<String, dynamic>>> getAllCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select('id, name')
          .order('name');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Error getting all companies
      return [];
    }
  }
}
