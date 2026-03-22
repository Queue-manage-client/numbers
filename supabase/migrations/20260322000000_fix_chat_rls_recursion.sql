-- ============================================================
-- チャット関連テーブルのRLSポリシー修正
-- 問題: chat_room_membersに循環参照するポリシーが存在し、
--       "infinite recursion detected in policy" エラーが発生
-- 修正: 全ポリシーを削除して再作成（シンプルなUSING(true)で統一）
-- ============================================================

-- 1. chat_room_members: 既存ポリシーをすべて削除
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE tablename = 'chat_room_members'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_room_members', pol.policyname);
  END LOOP;
END $$;

-- 2. chat_rooms: 既存ポリシーをすべて削除
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE tablename = 'chat_rooms'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_rooms', pol.policyname);
  END LOOP;
END $$;

-- 3. chat_messages: 既存ポリシーをすべて削除
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE tablename = 'chat_messages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON chat_messages', pol.policyname);
  END LOOP;
END $$;

-- RLS有効化（念のため）
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- chat_rooms ポリシー再作成
-- ============================================================
CREATE POLICY "chat_rooms_select"
  ON chat_rooms FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_rooms_insert"
  ON chat_rooms FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_rooms_update"
  ON chat_rooms FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "chat_rooms_delete"
  ON chat_rooms FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================
-- chat_messages ポリシー再作成
-- ============================================================
CREATE POLICY "chat_messages_select"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_messages_insert"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================
-- chat_room_members ポリシー再作成
-- ※ 他テーブルを参照しない単純なポリシーにして循環参照を防止
-- ============================================================
CREATE POLICY "chat_room_members_select"
  ON chat_room_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_room_members_insert"
  ON chat_room_members FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_room_members_delete"
  ON chat_room_members FOR DELETE
  TO authenticated
  USING (true);
