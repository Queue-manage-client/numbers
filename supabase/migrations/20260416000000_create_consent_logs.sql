-- ============================================================
-- 同意記録テーブル作成マイグレーション
-- 法人登録時の利用規約・プライバシーポリシー・法人向け契約条項への
-- 同意を記録するための追記専用テーブル
-- ============================================================

-- ============================================================
-- 1. consent_logs テーブル作成
-- ============================================================
CREATE TABLE IF NOT EXISTS consent_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid REFERENCES companies(id) ON DELETE SET NULL,

  -- 同意内容
  agreement_type text NOT NULL,       -- 'terms', 'privacy', 'company_contract'
  agreement_version text NOT NULL,    -- 'v1.0' など

  -- 同意メタデータ
  accepted_at timestamptz NOT NULL DEFAULT now(),
  ip_address text,                    -- クライアントIP
  device_info jsonb,                  -- 端末情報 (OS, モデル, アプリバージョン等)

  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 2. RLSポリシー設定（追記専用・管理者のみ閲覧可）
-- ============================================================
ALTER TABLE consent_logs ENABLE ROW LEVEL SECURITY;

-- 認証ユーザーは自分の同意記録をINSERTのみ可能
CREATE POLICY "Users can insert own consent logs"
  ON consent_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 管理者は全件閲覧可能
CREATE POLICY "Admins can read all consent logs"
  ON consent_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- UPDATE / DELETE ポリシーは作成しない（追記専用）

-- ============================================================
-- 3. インデックス
-- ============================================================
CREATE INDEX idx_consent_logs_user_id ON consent_logs(user_id);
CREATE INDEX idx_consent_logs_company_id ON consent_logs(company_id);
CREATE INDEX idx_consent_logs_accepted_at ON consent_logs(accepted_at DESC);
