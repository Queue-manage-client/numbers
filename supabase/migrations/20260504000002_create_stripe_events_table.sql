-- ============================================================
-- stripe_events テーブル
-- Stripe Webhook の冪等性確保
-- ============================================================

CREATE TABLE IF NOT EXISTS stripe_events (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  payload JSONB NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stripe_events_type ON stripe_events(type);

-- RLS: service_role のみアクセス可 (ポリシー無し)
ALTER TABLE stripe_events ENABLE ROW LEVEL SECURITY;
