-- companiesテーブルにSNS URLカラムを追加
ALTER TABLE companies ADD COLUMN IF NOT EXISTS sns_url text;
