-- ============================================================
-- SNSリンク複数対応マイグレーション
-- sns_links は以下の形式の配列:
--   [{"platform": "instagram", "url": "https://..."}, ...]
-- ============================================================

-- 新カラム追加
ALTER TABLE companies ADD COLUMN IF NOT EXISTS sns_links jsonb DEFAULT '[]'::jsonb;
