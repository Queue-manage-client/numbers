-- =========================================================
-- 管理者には MFA (AAL2) を強制する
-- Stripe セキュリティチェックリスト要件: 二段階認証
--
-- 既存の is_admin_caller() を上書きし、JWT の aal クレームが
-- 'aal2' であることを追加要件にする。
-- 既存管理者は MFA 未登録なら一切の admin 操作ができなくなるため、
-- 登録 (auth.mfa.factors への TOTP enroll) を済ませてから本マイグレーションを
-- 本番適用する運用とする。
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
  AND coalesce(
    (current_setting('request.jwt.claims', true)::jsonb ->> 'aal'),
    'aal1'
  ) = 'aal2';
$$;

REVOKE ALL ON FUNCTION is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_admin_caller() TO authenticated;

COMMENT ON FUNCTION is_admin_caller() IS
  '管理者ロール かつ MFA 二要素 (AAL2) 認証済みの呼び出しのみ true。';
