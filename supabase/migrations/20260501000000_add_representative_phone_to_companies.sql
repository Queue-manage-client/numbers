-- 企業テーブルに代表者名・電話番号カラムを追加
ALTER TABLE companies ADD COLUMN IF NOT EXISTS representative_name text;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS phone text;
