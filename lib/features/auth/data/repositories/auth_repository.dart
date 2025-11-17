import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: null,
    );

    // メール確認を自動的に設定
    if (response.user != null) {
      try {
        await _supabase.rpc('auto_confirm_email', params: {
          'user_id': response.user!.id,
        });
        
        // セッションを再取得して認証状態を確実に更新
        if (response.session == null) {
          // セッションがない場合は、パスワードでサインインしてセッションを確立
          final signInResponse = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return signInResponse;
        } else {
          // セッションがある場合はリフレッシュ
          await _supabase.auth.refreshSession();
        }
      } catch (e) {
        // エラーが発生した場合、パスワードでサインインを試みる
        try {
          final signInResponse = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return signInResponse;
        } catch (signInError) {
          // サインインも失敗した場合は元のレスポンスを返す
          print('メール確認設定エラー: $e');
          print('サインインエラー: $signInError');
        }
      }
    }

    // profilesテーブルへの挿入はDatabase Triggerが自動的に行う

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // メール確認エラーの場合、自動的に確認を設定して再試行
      if (e.statusCode == '400' && 
          (e.message.contains('Email not confirmed') || 
           e.message.contains('email_not_confirmed'))) {
        try {
          // メールアドレスからユーザーのメール確認を設定
          await _supabase.rpc('auto_confirm_email_by_email', params: {
            'user_email': email,
          });
          
          // メール確認を設定した後、再度サインインを試みる
          final response = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          
          return response;
        } catch (innerError) {
          // エラーが発生した場合は元のエラーを再スロー
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
