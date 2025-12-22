// intern/data/repositories/intern_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class InternRepository {
  final SupabaseClient _supabase;

  InternRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getInternships() async {
    final response = await _supabase
        .from('internships')
        .select('*, companies(*)')
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getInternship(String internshipId) async {
    final response = await _supabase
        .from('internships')
        .select('*, companies(*)')
        .eq('id', internshipId)
        .maybeSingle();

    return response;
  }
}
