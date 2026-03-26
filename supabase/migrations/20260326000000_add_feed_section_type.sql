-- feed_sectionsテーブルにsection_typeカラムを追加
-- 管理者がセクションのタイプ（動画/企業/視聴履歴）を選択できるようにする

ALTER TABLE feed_sections
ADD COLUMN IF NOT EXISTS section_type TEXT NOT NULL DEFAULT 'video'
CHECK (section_type IN ('video', 'company', 'watched_history'));

-- 企業セクション用のオフセット/リミット設定
ALTER TABLE feed_sections
ADD COLUMN IF NOT EXISTS company_offset INTEGER DEFAULT 0;

ALTER TABLE feed_sections
ADD COLUMN IF NOT EXISTS company_limit INTEGER DEFAULT 5;

COMMENT ON COLUMN feed_sections.section_type IS 'セクションの表示タイプ: video=動画一覧, company=企業一覧, watched_history=視聴履歴';
COMMENT ON COLUMN feed_sections.company_offset IS '企業セクションで表示する企業リストの開始位置';
COMMENT ON COLUMN feed_sections.company_limit IS '企業セクションで表示する企業の最大件数';
