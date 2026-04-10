-- アプリ内履歴書ビルダー用カラムを追加
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_data JSONB;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_photo_url TEXT;
