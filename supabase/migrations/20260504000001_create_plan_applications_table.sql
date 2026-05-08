-- ============================================================
-- plan_applications テーブル
-- 商工会・特別プラン申請の審査記録
-- ============================================================

CREATE TABLE IF NOT EXISTS plan_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  requested_plan_code TEXT NOT NULL REFERENCES subscription_plans(code),
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  evidence_url TEXT,
  applicant_note TEXT,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 同一 (company, plan) で pending 1 件まで
CREATE UNIQUE INDEX IF NOT EXISTS uniq_plan_apps_pending_per_company_plan
  ON plan_applications(company_id, requested_plan_code)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_plan_apps_company ON plan_applications(company_id);
CREATE INDEX IF NOT EXISTS idx_plan_apps_status ON plan_applications(status);

-- RLS
ALTER TABLE plan_applications ENABLE ROW LEVEL SECURITY;

-- 自社の申請のみ参照可能 (profiles.company_id で関連)
DROP POLICY IF EXISTS "Company can read own plan applications" ON plan_applications;
CREATE POLICY "Company can read own plan applications"
  ON plan_applications FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = plan_applications.company_id
    )
  );

-- 自社の申請のみ作成可能
DROP POLICY IF EXISTS "Company can create own plan applications" ON plan_applications;
CREATE POLICY "Company can create own plan applications"
  ON plan_applications FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = plan_applications.company_id
    )
  );

-- UPDATE / DELETE は service_role 専用 (admin 機能経由)
