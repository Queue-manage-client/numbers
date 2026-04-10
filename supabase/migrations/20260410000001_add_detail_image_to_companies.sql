-- 企業詳細ページ用の画像URLカラムを追加
ALTER TABLE companies ADD COLUMN IF NOT EXISTS detail_image_url TEXT;
