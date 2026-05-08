-- ============================================================
-- 申請審査の admin 専用 stored function
-- approve: status 更新 + companies.eligible_plan_codes に追加 (アトミック)
-- reject:  status 更新 + 理由保存
-- ============================================================

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
  );
$$;

REVOKE ALL ON FUNCTION is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_admin_caller() TO authenticated;

-- ------------------------------------------------------------
-- approve_plan_application
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION approve_plan_application(application_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company_id UUID;
  v_plan_code TEXT;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Permission denied: admin only';
  END IF;

  SELECT company_id, requested_plan_code
  INTO v_company_id, v_plan_code
  FROM plan_applications
  WHERE id = application_id;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Application not found';
  END IF;

  UPDATE plan_applications SET
    status = 'approved',
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  WHERE id = application_id;

  UPDATE companies SET
    eligible_plan_codes = (
      SELECT ARRAY(
        SELECT DISTINCT unnest(eligible_plan_codes || ARRAY[v_plan_code])
      )
    )
  WHERE id = v_company_id;
END;
$$;

REVOKE ALL ON FUNCTION approve_plan_application(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION approve_plan_application(UUID) TO authenticated;

-- ------------------------------------------------------------
-- reject_plan_application
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION reject_plan_application(
  application_id UUID,
  reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Permission denied: admin only';
  END IF;

  UPDATE plan_applications SET
    status = 'rejected',
    rejection_reason = reason,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  WHERE id = application_id;
END;
$$;

REVOKE ALL ON FUNCTION reject_plan_application(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reject_plan_application(UUID, TEXT) TO authenticated;

-- ------------------------------------------------------------
-- admin に plan_applications の SELECT 権限を付与
-- ------------------------------------------------------------
CREATE POLICY "Admins can read all plan applications"
  ON plan_applications FOR SELECT
  TO authenticated
  USING (is_admin_caller());
