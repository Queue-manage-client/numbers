-- ============================================================
-- chat_rooms の INSERT/UPDATE/DELETE を自社のみに制限
-- (これまで USING/WITH CHECK が true で他社のチャットルームも操作できた)
-- ============================================================

DROP POLICY IF EXISTS "chat_rooms_insert" ON chat_rooms;
DROP POLICY IF EXISTS "Authenticated users can create chat rooms" ON chat_rooms;
CREATE POLICY "Own company can create chat rooms"
  ON chat_rooms FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = chat_rooms.company_id
    )
  );

DROP POLICY IF EXISTS "chat_rooms_update" ON chat_rooms;
CREATE POLICY "Own company can update chat rooms"
  ON chat_rooms FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = chat_rooms.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = chat_rooms.company_id
    )
  );

DROP POLICY IF EXISTS "chat_rooms_delete" ON chat_rooms;
CREATE POLICY "Own company can delete chat rooms"
  ON chat_rooms FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.company_id = chat_rooms.company_id
    )
  );
