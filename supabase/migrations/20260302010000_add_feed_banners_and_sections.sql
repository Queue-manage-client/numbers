-- バナーテーブル（Adminが設定するバナー画像、最大10枚）
CREATE TABLE IF NOT EXISTS feed_banners (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  image_url text NOT NULL,
  link_url text,
  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 特集セクションテーブル（Adminが設定する文言とセクション順序）
CREATE TABLE IF NOT EXISTS feed_sections (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- セクションに紐づく動画（Adminが選択）
CREATE TABLE IF NOT EXISTS feed_section_videos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  section_id uuid NOT NULL REFERENCES feed_sections(id) ON DELETE CASCADE,
  video_id uuid NOT NULL REFERENCES company_videos(id) ON DELETE CASCADE,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(section_id, video_id)
);

-- RLS有効化
ALTER TABLE feed_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_section_videos ENABLE ROW LEVEL SECURITY;

-- 誰でも閲覧可能（公開データ）
CREATE POLICY "Anyone can read active banners" ON feed_banners FOR SELECT TO public USING (is_active = true);
CREATE POLICY "Anyone can read active sections" ON feed_sections FOR SELECT TO public USING (is_active = true);
CREATE POLICY "Anyone can read section videos" ON feed_section_videos FOR SELECT TO public USING (true);

-- Admin（認証済みユーザー）が全操作可能
CREATE POLICY "Authenticated users can manage banners" ON feed_banners FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage sections" ON feed_sections FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can manage section videos" ON feed_section_videos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- バナー画像用ストレージバケット
INSERT INTO storage.buckets (id, name, public)
VALUES ('banners', 'banners', true)
ON CONFLICT (id) DO NOTHING;

-- バナーストレージポリシー
CREATE POLICY "Anyone can read banners" ON storage.objects FOR SELECT TO public USING (bucket_id = 'banners');
CREATE POLICY "Authenticated users can upload banners" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'banners');
CREATE POLICY "Authenticated users can update banners" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'banners');
CREATE POLICY "Authenticated users can delete banners" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'banners');

-- インデックス
CREATE INDEX IF NOT EXISTS idx_feed_banners_sort ON feed_banners(sort_order) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_feed_sections_sort ON feed_sections(sort_order) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_feed_section_videos_section ON feed_section_videos(section_id, sort_order);
