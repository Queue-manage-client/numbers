-- =========================================================
-- 管理者用メール OTP 認証 (Stripe チェックリスト 1-b: 二段階認証)
-- TOTP MFA から切替: パスワード + メール OTP の 2 段階
--
-- 1. admin_login_otp_codes: 発行された OTP コード (SHA-256 ハッシュ)
-- 2. admin_session_verifications: OTP 検証済みセッション (8 時間有効)
-- 3. is_admin_caller(): 「admin ロール + 有効な session_verification」に変更
-- 4. is_admin_verified() RPC: クライアントから検証済み状態を確認
-- =========================================================

-- OTP コード保存
CREATE TABLE IF NOT EXISTS admin_login_otp_codes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code_hash  text NOT NULL,
  attempts   int NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admin_login_otp_codes_user_idx
  ON admin_login_otp_codes (user_id);
CREATE INDEX IF NOT EXISTS admin_login_otp_codes_expires_idx
  ON admin_login_otp_codes (expires_at);

ALTER TABLE admin_login_otp_codes ENABLE ROW LEVEL SECURITY;
-- service_role のみアクセス (Edge Function で操作)

-- 検証済みセッション
CREATE TABLE IF NOT EXISTS admin_session_verifications (
  user_id     uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  verified_at timestamptz NOT NULL DEFAULT now(),
  expires_at  timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS admin_session_verifications_expires_idx
  ON admin_session_verifications (expires_at);

ALTER TABLE admin_session_verifications ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- is_admin_caller(): AAL2 要件を撤回し、OTP 検証済みを必須に
-- =========================================================
CREATE OR REPLACE FUNCTION is_admin_caller()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
  AND EXISTS (
    SELECT 1 FROM admin_session_verifications
    WHERE user_id = auth.uid()
      AND expires_at > now()
  );
$$;

REVOKE ALL ON FUNCTION is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_admin_caller() TO authenticated;
COMMENT ON FUNCTION is_admin_caller() IS
  '管理者ロール かつ メール OTP 検証済みセッションの場合のみ true。';

-- =========================================================
-- is_admin_verified(): クライアントから検証済み状態を確認
-- =========================================================
CREATE OR REPLACE FUNCTION is_admin_verified()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_session_verifications
    WHERE user_id = auth.uid()
      AND expires_at > now()
  );
$$;

REVOKE ALL ON FUNCTION is_admin_verified() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_admin_verified() TO authenticated;

-- Edge Function (service_role) からの操作権限
GRANT ALL ON TABLE admin_login_otp_codes TO service_role;
GRANT ALL ON TABLE admin_session_verifications TO service_role;
