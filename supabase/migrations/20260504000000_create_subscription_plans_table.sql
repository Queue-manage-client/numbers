-- ============================================================
-- subscription_plans マスタテーブル
-- 3 プラン (商工会 / 特別 / 通常) × 月額・年額 = 6 SKU を Stripe Price ID で管理
-- ============================================================

CREATE TABLE IF NOT EXISTS subscription_plans (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  stripe_price_id_monthly TEXT,
  stripe_price_id_yearly TEXT,
  monthly_amount INTEGER NOT NULL,
  yearly_amount INTEGER,
  requires_approval BOOLEAN NOT NULL DEFAULT false,
  is_public BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_is_public
  ON subscription_plans(is_public);

-- 初期データ (Stripe Price ID は Stripe ダッシュボードで Price 作成後に UPDATE する)
INSERT INTO subscription_plans
  (code, name, monthly_amount, yearly_amount, requires_approval, is_public, display_order)
VALUES
  ('standard', '通常プラン', 10999, NULL, false, true,  30),
  ('special',  '特別プラン',  9899, NULL, true,  false, 20),
  ('shokokai', '商工会プラン', 1100, NULL, true,  false, 10)
ON CONFLICT (code) DO NOTHING;

-- RLS: 認証済みユーザーは閲覧可、書き込みは service_role のみ
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read subscription plans" ON subscription_plans;
CREATE POLICY "Authenticated users can read subscription plans"
  ON subscription_plans FOR SELECT
  TO authenticated
  USING (true);
