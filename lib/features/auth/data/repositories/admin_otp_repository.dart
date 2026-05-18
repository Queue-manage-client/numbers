// auth/data/repositories/admin_otp_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOtpRepository {
  final SupabaseClient _supabase;

  AdminOtpRepository(this._supabase);

  /// 管理者ログイン直後にメール OTP を送信させる
  Future<void> requestOtp() async {
    await _supabase.functions.invoke(
      'send-admin-otp',
      method: HttpMethod.post,
    );
  }

  /// 入力された 6 桁コードを検証
  Future<void> verifyOtp(String code) async {
    final res = await _supabase.functions.invoke(
      'verify-admin-otp',
      method: HttpMethod.post,
      body: {'code': code},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['ok'] != true) {
      final msg = data?['error'] as String? ?? 'OTP 検証に失敗しました';
      throw Exception(msg);
    }
  }

  /// 現セッションが OTP 検証済みかを RPC で確認
  Future<bool> isVerified() async {
    try {
      final res = await _supabase.rpc('is_admin_verified');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
