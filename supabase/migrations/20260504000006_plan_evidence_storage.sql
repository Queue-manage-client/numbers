-- ============================================================
-- plan-evidence Storage バケット (申請審査用エビデンス)
-- private バケット。アップロード時の path = "<company_id>/<filename>"
-- 自社のみアップロード/読み取り可、admin は全件読み取り可
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('plan-evidence', 'plan-evidence', false)
ON CONFLICT (id) DO NOTHING;

-- 自社の company_id フォルダにのみアップロード可
DROP POLICY IF EXISTS "Company can upload own plan evidence" ON storage.objects;
CREATE POLICY "Company can upload own plan evidence"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'plan-evidence'
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND (storage.foldername(name))[1] = p.company_id::text
    )
  );

-- 自社のエビデンスのみ参照可
DROP POLICY IF EXISTS "Company can read own plan evidence" ON storage.objects;
CREATE POLICY "Company can read own plan evidence"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'plan-evidence'
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND (storage.foldername(name))[1] = p.company_id::text
    )
  );

-- admin は全件参照可
DROP POLICY IF EXISTS "Admin can read all plan evidence" ON storage.objects;
CREATE POLICY "Admin can read all plan evidence"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'plan-evidence'
    AND is_admin_caller()
  );
