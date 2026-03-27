-- feed_section_videos にセクション固有のサムネイルカラムを追加
-- thumbnail_url: 通常セクション用（横長）
-- highlight_thumbnail_url: 注目セクション用（縦長）
ALTER TABLE feed_section_videos ADD COLUMN IF NOT EXISTS thumbnail_url text;
ALTER TABLE feed_section_videos ADD COLUMN IF NOT EXISTS highlight_thumbnail_url text;

-- セクションサムネイル用ストレージバケット
INSERT INTO storage.buckets (id, name, public)
VALUES ('section-thumbnails', 'section-thumbnails', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Anyone can read section thumbnails"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'section-thumbnails');

CREATE POLICY "Authenticated users can upload section thumbnails"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'section-thumbnails');

CREATE POLICY "Authenticated users can update section thumbnails"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'section-thumbnails');

CREATE POLICY "Authenticated users can delete section thumbnails"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'section-thumbnails');
