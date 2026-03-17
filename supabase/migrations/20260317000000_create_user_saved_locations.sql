-- ============================================================
-- user_saved_locations テーブル作成
-- マップ機能で使用する、ユーザーの保存済み地点（自宅・学校・会社等）
-- ============================================================

CREATE TABLE IF NOT EXISTS user_saved_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- upsert用のユニーク制約（user_id + name で一意）
  UNIQUE (user_id, name)
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_user_saved_locations_user_id
  ON user_saved_locations(user_id);

-- RLS有効化
ALTER TABLE user_saved_locations ENABLE ROW LEVEL SECURITY;

-- ユーザーは自分の保存地点を閲覧可能
CREATE POLICY "Users can read own saved locations"
  ON user_saved_locations FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- ユーザーは自分の保存地点を作成可能
CREATE POLICY "Users can create own saved locations"
  ON user_saved_locations FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ユーザーは自分の保存地点を更新可能
CREATE POLICY "Users can update own saved locations"
  ON user_saved_locations FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ユーザーは自分の保存地点を削除可能
CREATE POLICY "Users can delete own saved locations"
  ON user_saved_locations FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());
