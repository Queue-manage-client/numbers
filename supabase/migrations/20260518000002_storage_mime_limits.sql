-- =========================================================
-- ストレージバケットの MIME / サイズ制限
-- Stripe セキュリティチェックリスト要件:
--   「Web サーバーや Web アプリケーションによりアップロード可能な
--     拡張子やファイルを制限する等の設定を行う」
--
-- 既存バケットには UPDATE で制限を後付けする。
-- 新規バケットを作る migration では INSERT 時にも同じ制限を指定すること。
-- =========================================================

-- documents: 履歴書 (PDF / Word) + 画像
UPDATE storage.buckets
   SET file_size_limit = 10485760, -- 10 MiB
       allowed_mime_types = ARRAY[
         'application/pdf',
         'application/msword',
         'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
         'image/jpeg',
         'image/png',
         'image/webp'
       ]
 WHERE id = 'documents';

-- banners: 公開バナー画像
UPDATE storage.buckets
   SET file_size_limit = 5242880, -- 5 MiB
       allowed_mime_types = ARRAY[
         'image/jpeg',
         'image/png',
         'image/webp',
         'image/gif'
       ]
 WHERE id = 'banners';

-- section-thumbnails: フィードセクション用サムネイル
UPDATE storage.buckets
   SET file_size_limit = 5242880,
       allowed_mime_types = ARRAY[
         'image/jpeg',
         'image/png',
         'image/webp'
       ]
 WHERE id = 'section-thumbnails';

-- plan-evidence: 加盟店審査の証憑書類
UPDATE storage.buckets
   SET file_size_limit = 20971520, -- 20 MiB
       allowed_mime_types = ARRAY[
         'application/pdf',
         'image/jpeg',
         'image/png',
         'image/webp'
       ]
 WHERE id = 'plan-evidence';

-- company-videos: 企業の動画
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'company-videos',
  'company-videos',
  true,
  524288000, -- 500 MiB
  ARRAY['video/mp4', 'video/quicktime', 'video/webm']
)
ON CONFLICT (id) DO UPDATE
  SET file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- company-thumbnails: 企業の画像
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'company-thumbnails',
  'company-thumbnails',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- chat-icons: チャット用アイコン
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-icons',
  'chat-icons',
  false,
  2097152, -- 2 MiB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;
