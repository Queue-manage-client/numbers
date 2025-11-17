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
    if (skills != null) data['skills'] = skills;
    if (jobPreferences != null) data['job_preferences'] = jobPreferences;

    await _supabase.from('profiles').update(data).eq('id', userId);
  }
}
