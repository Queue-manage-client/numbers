-- ============================================================
-- 投稿系 RLS をサブスク必須に変更
-- approved AND active|trialing でのみ company_videos / jobs / internships の
-- INSERT / UPDATE / DELETE を許可する
-- ============================================================

-- 投稿可否判定関数 (profiles.company_id 経由で auth.uid() ↔ companies を関連)
CREATE OR REPLACE FUNCTION can_company_post(target_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM companies c
    JOIN profiles p ON p.company_id = c.id
    WHERE c.id = target_company_id
      AND p.id = auth.uid()
      AND c.approval_status = 'approved'
      AND c.subscription_status IN ('active', 'trialing')
  );
$$;

REVOKE ALL ON FUNCTION can_company_post(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION can_company_post(UUID) TO authenticated;

-- ------------------------------------------------------------
-- company_videos
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create videos" ON company_videos;
DROP POLICY IF EXISTS "Authenticated users can update videos" ON company_videos;
DROP POLICY IF EXISTS "Authenticated users can delete videos" ON company_videos;

CREATE POLICY "Subscribed company can create videos"
  ON company_videos FOR INSERT
  TO authenticated
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can update own videos"
  ON company_videos FOR UPDATE
  TO authenticated
  USING (can_company_post(company_id))
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can delete own videos"
  ON company_videos FOR DELETE
  TO authenticated
  USING (can_company_post(company_id));

-- ------------------------------------------------------------
-- jobs
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create jobs" ON jobs;
DROP POLICY IF EXISTS "Authenticated users can update jobs" ON jobs;
DROP POLICY IF EXISTS "Authenticated users can delete jobs" ON jobs;

CREATE POLICY "Subscribed company can create jobs"
  ON jobs FOR INSERT
  TO authenticated
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can update own jobs"
  ON jobs FOR UPDATE
  TO authenticated
  USING (can_company_post(company_id))
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can delete own jobs"
  ON jobs FOR DELETE
  TO authenticated
  USING (can_company_post(company_id));

-- ------------------------------------------------------------
-- internships
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create internships" ON internships;
DROP POLICY IF EXISTS "Authenticated users can update internships" ON internships;
DROP POLICY IF EXISTS "Authenticated users can delete internships" ON internships;

CREATE POLICY "Subscribed company can create internships"
  ON internships FOR INSERT
  TO authenticated
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can update own internships"
  ON internships FOR UPDATE
  TO authenticated
  USING (can_company_post(company_id))
  WITH CHECK (can_company_post(company_id));

CREATE POLICY "Subscribed company can delete own internships"
  ON internships FOR DELETE
  TO authenticated
  USING (can_company_post(company_id));
