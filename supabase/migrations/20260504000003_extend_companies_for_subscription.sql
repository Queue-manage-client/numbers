-- ============================================================
-- companies テーブル サブスク関連カラム追加
-- ============================================================

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_status TEXT,
  ADD COLUMN IF NOT EXISTS current_plan_code TEXT REFERENCES subscription_plans(code),
  ADD COLUMN IF NOT EXISTS current_billing_cycle TEXT CHECK (current_billing_cycle IN ('monthly', 'yearly')),
  ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS eligible_plan_codes TEXT[] NOT NULL DEFAULT ARRAY['standard']::TEXT[];

-- 一意制約
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'companies_stripe_customer_id_key'
  ) THEN
    ALTER TABLE companies ADD CONSTRAINT companies_stripe_customer_id_key UNIQUE (stripe_customer_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'companies_stripe_subscription_id_key'
  ) THEN
    ALTER TABLE companies ADD CONSTRAINT companies_stripe_subscription_id_key UNIQUE (stripe_subscription_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_companies_subscription_status ON companies(subscription_status);
CREATE INDEX IF NOT EXISTS idx_companies_stripe_customer_id ON companies(stripe_customer_id);
