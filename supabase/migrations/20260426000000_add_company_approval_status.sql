-- ============================================================
-- 企業審査ステータス管理マイグレーション
-- 法人アカウント登録後、運営側の審査を経て利用可能とする仕組み
-- ============================================================

-- ============================================================
-- 1. companies テーブルにカラム追加
-- ============================================================

-- 審査ステータス: 'pending'(審査待ち), 'approved'(審査通過), 'rejected'(審査否認)
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS approval_status text NOT NULL DEFAULT 'pending';

-- 審査メモ（否認理由など）
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS approval_note text;

-- 審査日時
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;

-- 審査した管理者のID
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- ============================================================
-- 2. 既存企業を承認済みに設定
-- ============================================================
UPDATE companies SET approval_status = 'approved' WHERE approval_status = 'pending';

-- ============================================================
-- 3. インデックス
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_companies_approval_status ON companies(approval_status);
