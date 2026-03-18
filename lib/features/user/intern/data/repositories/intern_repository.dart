// intern/data/repositories/intern_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:numbers/features/user/intern/domain/models/internship.dart';
import 'package:numbers/features/user/intern/domain/models/internship_application.dart';

class InternRepository {
  final SupabaseClient _supabase;

  InternRepository(this._supabase);

  // ========== インターン一覧・詳細 ==========

  Future<List<Map<String, dynamic>>> getInternships() async {
    try {
      final response = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getInternship(String internshipId) async {
    try {
      final response = await _supabase
          .from('internships')
          .select('*, companies(*)')
          .eq('id', internshipId)
          .maybeSingle();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ========== 申し込み機能 ==========

  /// インターンに申し込む
  Future<InternshipApplication> applyForInternship({
    required String internshipId,
    String? message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      final response = await _supabase
          .from('internship_applications')
          .insert({
            'internship_id': internshipId,
            'user_id': userId,
            'message': message,
          })
          .select()
          .single();

      return InternshipApplication.fromJson(response);
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
          .from('internship_applications')
          .update({'status': 'cancelled'})
          .eq('id', applicationId)
          .eq('user_id', userId)
          .eq('status', 'pending');
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーの申し込み一覧を取得
  Future<List<InternshipApplication>> getUserApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ログインが必要です');
    }

    try {
      final response = await _supabase
          .from('internship_applications')
          .select('*, internships(*, companies(*))')
          .eq('user_id', userId)
          .order('applied_at', ascending: false);

      return (response as List)
          .map((json) => InternshipApplication.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 特定インターンの申し込み状態を確認
  Future<InternshipApplication?> getApplicationStatus(String internshipId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    try {
      final response = await _supabase
          .from('internship_applications')
          .select()
          .eq('internship_id', internshipId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return InternshipApplication.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// 申し込み済みかどうかを確認
  Future<bool> hasApplied(String internshipId) async {
    try {
      final application = await getApplicationStatus(internshipId);
      return application != null && application.status != ApplicationStatus.cancelled;
    } catch (e) {
      rethrow;
    }
  }
}
