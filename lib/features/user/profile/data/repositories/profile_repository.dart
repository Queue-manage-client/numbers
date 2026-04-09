// profile/data/repositories/profile_repository.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? nickname,
    String? gender,
    DateTime? birthDate,
    String? location,
    String? university,
    String? education,
    List<String>? skills,
    Map<String, dynamic>? jobPreferences,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (nickname != null) data['nickname'] = nickname;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birth_date'] = birthDate.toIso8601String();
    if (location != null) data['location'] = location;
    if (university != null) data['university'] = university;
    if (education != null) data['education'] = education;
    if (skills != null) data['skills'] = skills;
    if (jobPreferences != null) data['job_preferences'] = jobPreferences;

    try {
      await _supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// 職務経歴書をアップロード
  Future<String?> uploadResume({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      // ファイル名に日本語や特殊文字が含まれるとStorageがエラーになるため、
      // タイムスタンプベースの安全なパスを生成し、元のファイル名はDB側に保存
      final ext = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')) : '.pdf';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'resumes/$userId/resume_$timestamp$ext';

      await _supabase.storage
          .from('documents')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      // プロフィールにストレージパスを保存（署名付きURLは取得時に生成）
      await _supabase.from('profiles').update({
        'resume_url': storagePath,
        'resume_file_name': fileName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return storagePath;
    } catch (e) {
      rethrow;
    }
  }

  /// 職務経歴書の署名付きURLを取得（1時間有効）
  Future<String?> getResumeSignedUrl(String storagePath) async {
    try {
      final result = await _supabase.storage
          .from('documents')
          .createSignedUrl(storagePath, 3600);
      return result;
    } catch (e) {
      return null;
    }
  }

  /// 職務経歴書を削除
  Future<void> deleteResume(String userId) async {
    try {
      // プロフィールからストレージパスを取得
      final profile = await getProfile(userId);
      final storagePath = profile?['resume_url'] as String?;

      // Storage上のファイルも削除
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await _supabase.storage
              .from('documents')
              .remove([storagePath]);
        } catch (_) {
          // Storage削除失敗は致命的ではない
        }
      }

      await _supabase.from('profiles').update({
        'resume_url': null,
        'resume_file_name': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
