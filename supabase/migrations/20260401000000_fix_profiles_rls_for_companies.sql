-- ============================================================
-- profilesテーブルのRLSポリシー修正
-- 問題: 企業ユーザーが応募者のプロフィール（職務経歴書含む）を閲覧できない
-- 修正: 認証済みユーザーは他ユーザーの基本プロフィールを閲覧可能に
-- ============================================================

-- 既存のSELECTポリシーを削除
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;

-- 認証済みユーザーは全プロフィールを閲覧可能
-- （企業が応募者のプロフィール・職務経歴書を確認するために必要）
CREATE POLICY "Authenticated users can read profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- UPDATEは自分のプロフィールのみ（既存のまま維持）
-- DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
-- すでに存在: USING (id = auth.uid()) WITH CHECK (id = auth.uid())
