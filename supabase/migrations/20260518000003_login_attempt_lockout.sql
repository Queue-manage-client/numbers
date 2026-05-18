-- =========================================================
-- ログイン失敗ロックアウト (Stripe チェックリスト 1-c / 6)
--   「アカウントロック機能を有効にし、10 回以下のログイン失敗で
--     アカウントをロックする」
--
-- 仕組み:
--   1. password-verification-attempt フックを Supabase Auth に登録
--      (Dashboard > Auth > Hooks で hook_password_verification_attempt を選択)
--   2. ログイン成功/失敗のたびに本関数が呼ばれる
--   3. 直近 LOCKOUT_WINDOW_MIN 分の失敗回数を集計
--   4. LOCKOUT_THRESHOLD 回以上で reject (LOCKOUT_DURATION_MIN 分間)
--   5. 成功時は失敗履歴をクリア
-- =========================================================

CREATE TABLE IF NOT EXISTS auth_failed_login_attempts (
  id           bigserial PRIMARY KEY,
  user_id      uuid NOT NULL,
  attempted_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS auth_failed_login_attempts_user_time_idx
  ON auth_failed_login_attempts (user_id, attempted_at DESC);

ALTER TABLE auth_failed_login_attempts ENABLE ROW LEVEL SECURITY;
-- service_role のみアクセス (Auth Hook は SECURITY DEFINER で動作するため一般ユーザー権限不要)

CREATE OR REPLACE FUNCTION hook_password_verification_attempt(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id     uuid := (event->>'user_id')::uuid;
  v_valid       boolean := (event->>'valid')::boolean;
  v_threshold   int := 10;
  v_window_min  int := 30;
  v_lock_min    int := 30;
  v_recent_fail int;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('decision', 'continue');
  END IF;

  -- 成功: 失敗履歴をクリアして通過
  IF v_valid THEN
    DELETE FROM auth_failed_login_attempts WHERE user_id = v_user_id;
    RETURN jsonb_build_object('decision', 'continue');
  END IF;

  -- 失敗: 直近の失敗回数をカウント
  SELECT count(*) INTO v_recent_fail
    FROM auth_failed_login_attempts
   WHERE user_id = v_user_id
     AND attempted_at > now() - make_interval(mins => v_window_min);

  -- 既に閾値超過なら reject (現在の失敗はカウントせず)
  IF v_recent_fail >= v_threshold THEN
    RETURN jsonb_build_object(
      'decision', 'reject',
      'message', format(
        'ログイン失敗回数の上限を超えました。%s 分後に再度お試しください。',
        v_lock_min
      )
    );
  END IF;

  -- 今回の失敗を記録
  INSERT INTO auth_failed_login_attempts (user_id) VALUES (v_user_id);

  -- 今回の失敗で閾値に達した場合もロックを返す
  IF v_recent_fail + 1 >= v_threshold THEN
    RETURN jsonb_build_object(
      'decision', 'reject',
      'message', format(
        'ログイン失敗回数の上限を超えました。%s 分後に再度お試しください。',
        v_lock_min
      )
    );
  END IF;

  -- 通常の失敗 (Supabase 側で 400 が返る)
  RETURN jsonb_build_object('decision', 'continue');
END;
$$;

REVOKE ALL ON FUNCTION hook_password_verification_attempt(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION hook_password_verification_attempt(jsonb) TO supabase_auth_admin;
GRANT ALL ON TABLE auth_failed_login_attempts TO supabase_auth_admin;
GRANT ALL ON SEQUENCE auth_failed_login_attempts_id_seq TO supabase_auth_admin;

COMMENT ON FUNCTION hook_password_verification_attempt(jsonb) IS
  '10 回失敗で 30 分ロック。Supabase Dashboard > Auth > Hooks で有効化必須。';
