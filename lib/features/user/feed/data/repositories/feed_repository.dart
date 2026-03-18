// feed/data/repositories/feed_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  /// フィード動画一覧を取得
  Future<List<Map<String, dynamic>>> fetchFeedVideos({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('company_videos')
          .select('*, companies(*)')
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      if (response == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      rethrow;
    }
  }

  /// 特定の動画を取得
  Future<Map<String, dynamic>?> fetchVideoById(String videoId) async {
    try {
      final response = await _supabase
          .from('company_videos')
          .select('*, companies(*)')
          .eq('id', videoId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 動画のブックマーク状態を切り替え
  Future<bool> toggleBookmark(String videoId, String userId) async {
    try {
      // 削除を試みて、削除できたかどうかで判定（TOCTOU回避）
      final deleted = await _supabase
          .from('bookmarks')
          .delete()
          .eq('video_id', videoId)
          .eq('user_id', userId)
          .select();

      if ((deleted as List).isNotEmpty) {
        // 削除できた → ブックマーク解除
        return false;
      }

      // 削除対象がなかった → 新規追加（競合時は無視）
      await _supabase.from('bookmarks').upsert(
        {
          'video_id': videoId,
          'user_id': userId,
        },
        onConflict: 'video_id, user_id',
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 動画の視聴履歴を記録
  Future<void> recordView(String videoId, String userId) async {
    try {
      await _supabase.from('video_views').insert({
        'video_id': videoId,
        'profile_id': userId,
      });
    } catch (_) {
      // 視聴履歴の記録失敗は致命的ではないのでエラーを投げない
    }
  }

  /// 視聴履歴を取得
  Future<List<Map<String, dynamic>>> getWatchHistory(String userId, {int limit = 30}) async {
    try {
      final response = await _supabase
          .from('video_views')
          .select('*, company_videos(*, companies(*))')
          .eq('profile_id', userId)
          .order('watched_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// 企業をフォロー
  Future<void> followCompany(String companyId, String userId) async {
    try {
      await _supabase.from('company_follows').insert({
        'company_id': companyId,
        'user_id': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 企業のフォローを解除
  Future<void> unfollowCompany(String companyId, String userId) async {
    try {
      await _supabase
          .from('company_follows')
          .delete()
          .eq('company_id', companyId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// 動画URLを取得（Supabase Storage - 署名付きURL）
  Future<String> getVideoUrl(String videoPath) async {
    try {
      if (videoPath.startsWith('http')) return videoPath;
      return await _supabase.storage
          .from('company-videos')
          .createSignedUrl(videoPath, 3600);
    } catch (e) {
      rethrow;
    }
  }

  /// サムネイルURLを取得（Supabase Storage - 署名付きURL）
  Future<String> getThumbnailUrl(String thumbnailPath) async {
    try {
      if (thumbnailPath.startsWith('http')) return thumbnailPath;
      return await _supabase.storage
          .from('company-thumbnails')
          .createSignedUrl(thumbnailPath, 3600);
    } catch (e) {
      rethrow;
    }
  }
}