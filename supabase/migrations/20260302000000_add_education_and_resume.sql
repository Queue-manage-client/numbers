-- profilesテーブルに学歴・職務経歴書カラムを追加
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS education text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_url text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_file_name text;

-- 既存のuniversityデータをeducationにコピー
UPDATE profiles SET education = university WHERE education IS NULL AND university IS NOT NULL;

-- documentsストレージバケットを作成（公開）
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- ストレージポリシー: 認証ユーザーが自分のフォルダにアップロード可能
CREATE POLICY "Users can upload their own resumes"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = 'resumes'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 認証ユーザーが自分のファイルを更新可能
CREATE POLICY "Users can update their own resumes"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = 'resumes'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 認証ユーザーが自分のファイルを削除可能
CREATE POLICY "Users can delete their own resumes"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = 'resumes'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 公開バケットなので誰でも閲覧可能
CREATE POLICY "Anyone can read documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'documents');
