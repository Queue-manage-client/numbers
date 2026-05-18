-- =========================================================
-- password_verification_attempt フックを削除
-- 理由: Supabase Team/Enterprise プラン限定で Free/Pro では使用不可
--
-- 代替実装: Edge Function record-login-failure で
-- ログイン失敗を auth_failed_login_attempts に記録し、
-- 閾値超過時に auth.users.banned_until を更新する。
-- (auth_failed_login_attempts テーブル自体は残す)
-- =========================================================

DROP FUNCTION IF EXISTS hook_password_verification_attempt(jsonb);
