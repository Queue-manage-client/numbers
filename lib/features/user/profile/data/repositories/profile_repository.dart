// profile/data/repositories/profile_repository.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
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

    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  /// 職務経歴書をアップロード
  Future<String?> uploadResume({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    final file = File(filePath);
    final storagePath = 'resumes/$userId/$fileName';

    await _supabase.storage
        .from('documents')
        .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

    final url = _supabase.storage
        .from('documents')
        .getPublicUrl(storagePath);

    // プロフィールに職務経歴書URLを保存
    await _supabase.from('profiles').update({
      'resume_url': url,
      'resume_file_name': fileName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    return url;
  }

  /// 職務経歴書を削除
  Future<void> deleteResume(String userId) async {
    await _supabase.from('profiles').update({
      'resume_url': null,
      'resume_file_name': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
