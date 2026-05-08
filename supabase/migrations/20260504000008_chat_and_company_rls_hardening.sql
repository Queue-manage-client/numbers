-- ============================================================
-- chat_messages / chat_room_members / companies の RLS 強化
-- これまで INSERT/DELETE が WITH CHECK true で誰でも操作可能だった
-- ============================================================

-- ------------------------------------------------------------
-- chat_messages: 自分がメンバーの room にのみメッセージ投稿可
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;
DROP POLICY IF EXISTS "Authenticated users can send chat messages" ON chat_messages;
CREATE POLICY "Members can send chat messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_room_members crm
      WHERE crm.room_id = chat_messages.room_id
        AND crm.profile_id = auth.uid()
    )
  );

-- ------------------------------------------------------------
-- chat_room_members INSERT: 自分自身を追加 OR 自社の room へのメンバー追加
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "chat_room_members_insert" ON chat_room_members;
DROP POLICY IF EXISTS "Authenticated users can join chat rooms" ON chat_room_members;
CREATE POLICY "Self or own company can add room members"
  ON chat_room_members FOR INSERT
  TO authenticated
  WITH CHECK (
    chat_room_members.profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      JOIN chat_rooms cr ON cr.company_id = p.company_id
      WHERE p.id = auth.uid()
        AND cr.id = chat_room_members.room_id
    )
  );

-- ------------------------------------------------------------
-- chat_room_members DELETE: 自分自身を退出 OR 自社の room から削除
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "chat_room_members_delete" ON chat_room_members;
CREATE POLICY "Self or own company can remove room members"
  ON chat_room_members FOR DELETE
  TO authenticated
  USING (
    chat_room_members.profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      JOIN chat_rooms cr ON cr.company_id = p.company_id
      WHERE p.id = auth.uid()
        AND cr.id = chat_room_members.room_id
    )
  );

-- ------------------------------------------------------------
-- companies INSERT: 自分の profile.company_id が NULL のときのみ
-- (新規企業登録時の自分用作成だけを許可。
--  既に企業に所属しているユーザーが追加で会社を作れないようにする)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create companies" ON companies;
DROP POLICY IF EXISTS "Company users can create companies" ON companies;
CREATE POLICY "Unaffiliated user can create own company"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id IS NULL
    )
  );
