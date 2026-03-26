import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'user',
    String? nickname,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      },
    );

    // サインアップ成功後にprofilesのニックネームを更新
    if (response.user != null && nickname != null && nickname.isNotEmpty) {
      try {
        await _supabase.from('profiles').update({
          'nickname': nickname,
        }).eq('id', response.user!.id);
      } catch (_) {
        // プロフィール更新失敗は致命的ではない（後から編集可能）
      }
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
