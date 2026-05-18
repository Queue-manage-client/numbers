import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'user',
    String? nickname,
    String? captchaToken,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      captchaToken: captchaToken,
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
    String? captchaToken,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
      if (response.user != null) {
        unawaited(_sendLoginNotification());
      }
      return response;
    } on AuthException catch (_) {
      // 失敗をサーバ側にカウントし、N 回超過なら banned_until を更新
      unawaited(_recordLoginFailure(email));
      rethrow;
    }
  }

  Future<void> _sendLoginNotification() async {
    try {
      await _supabase.functions.invoke(
        'send-login-notification',
        method: HttpMethod.post,
      );
    } catch (_) {
      // 通知メール送信失敗はサイレント
    }
  }

  Future<void> _recordLoginFailure(String email) async {
    try {
      await _supabase.functions.invoke(
        'record-login-failure',
        method: HttpMethod.post,
        body: {'email': email.trim()},
      );
    } catch (_) {
      // 記録失敗はサイレント
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
