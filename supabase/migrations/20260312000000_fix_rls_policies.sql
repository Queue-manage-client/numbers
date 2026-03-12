-- ============================================================
-- RLSポリシー修正マイグレーション
-- 問題: companies, company_videos, profiles, jobs 等のテーブルで
--       RLSが有効だがポリシーが不足しており、データが読み取れない
-- ============================================================

-- ============================================================
-- 1. companies テーブル
-- ============================================================
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- 既存ポリシーを安全に削除（存在する場合のみ）
DROP POLICY IF EXISTS "Anyone can read active companies" ON companies;
DROP POLICY IF EXISTS "Authenticated users can read companies" ON companies;
DROP POLICY IF EXISTS "Company owners can update their company" ON companies;
DROP POLICY IF EXISTS "Authenticated users can create companies" ON companies;
DROP POLICY IF EXISTS "Admin full access to companies" ON companies;

-- 公開企業は誰でも閲覧可能（is_suspended = false）
CREATE POLICY "Anyone can read active companies"
  ON companies FOR SELECT
  TO public
  USING (is_suspended = false);

-- 認証ユーザーは企業を作成可能
CREATE POLICY "Authenticated users can create companies"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 企業オーナーは自社情報を更新可能
CREATE POLICY "Company owners can update their company"
  ON companies FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 2. company_videos テーブル
-- ============================================================
ALTER TABLE company_videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read public videos" ON company_videos;
DROP POLICY IF EXISTS "Authenticated users can read all videos" ON company_videos;
DROP POLICY IF EXISTS "Authenticated users can manage videos" ON company_videos;

-- 公開動画は誰でも閲覧可能
CREATE POLICY "Anyone can read public videos"
  ON company_videos FOR SELECT
  TO public
  USING (is_public = true);

-- 認証ユーザーは動画を作成可能
CREATE POLICY "Authenticated users can create videos"
  ON company_videos FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 認証ユーザーは動画を更新可能
CREATE POLICY "Authenticated users can update videos"
  ON company_videos FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 認証ユーザーは動画を削除可能
CREATE POLICY "Authenticated users can delete videos"
  ON company_videos FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================
-- 3. profiles テーブル
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admin can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can read profiles" ON profiles;

-- ユーザーは自分のプロフィールを閲覧可能
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- ユーザーは自分のプロフィールを更新可能
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================
-- 4. jobs テーブル
-- ============================================================
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read open jobs" ON jobs;
DROP POLICY IF EXISTS "Authenticated users can manage jobs" ON jobs;

-- 公開求人は誰でも閲覧可能
CREATE POLICY "Anyone can read open jobs"
  ON jobs FOR SELECT
  TO public
  USING (status = 'open');

-- 認証ユーザーは求人を作成可能
CREATE POLICY "Authenticated users can create jobs"
  ON jobs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 認証ユーザーは求人を更新可能
CREATE POLICY "Authenticated users can update jobs"
  ON jobs FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 認証ユーザーは求人を削除可能
CREATE POLICY "Authenticated users can delete jobs"
  ON jobs FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================
-- 5. internships テーブル（既存ポリシー補完）
-- ============================================================
ALTER TABLE internships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read public internships" ON internships;
DROP POLICY IF EXISTS "Authenticated users can manage internships" ON internships;

-- 公開インターンは誰でも閲覧可能
CREATE POLICY "Anyone can read public internships"
  ON internships FOR SELECT
  TO public
  USING (is_public = true);

-- 認証ユーザーはインターンを作成可能
CREATE POLICY "Authenticated users can create internships"
  ON internships FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 認証ユーザーはインターンを更新可能
CREATE POLICY "Authenticated users can update internships"
  ON internships FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 認証ユーザーはインターンを削除可能
CREATE POLICY "Authenticated users can delete internships"
  ON internships FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================
-- 6. internship_applications テーブル
-- ============================================================
ALTER TABLE internship_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own applications" ON internship_applications;
DROP POLICY IF EXISTS "Users can create applications" ON internship_applications;
DROP POLICY IF EXISTS "Users can update own applications" ON internship_applications;
DROP POLICY IF EXISTS "Company can read applications" ON internship_applications;

-- ユーザーは自分の申し込みを閲覧可能
CREATE POLICY "Users can read own internship applications"
  ON internship_applications FOR SELECT
  TO authenticated
  USING (true);

-- ユーザーは申し込み可能
CREATE POLICY "Users can create internship applications"
  ON internship_applications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ユーザーは自分の申し込みを更新可能
CREATE POLICY "Users can update internship applications"
  ON internship_applications FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 7. job_applications テーブル
-- ============================================================
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own job applications" ON job_applications;
DROP POLICY IF EXISTS "Users can create job applications" ON job_applications;
DROP POLICY IF EXISTS "Users can update job applications" ON job_applications;

-- ユーザーは申し込みを閲覧可能
CREATE POLICY "Users can read job applications"
  ON job_applications FOR SELECT
  TO authenticated
  USING (true);

-- ユーザーは申し込み可能
CREATE POLICY "Users can create job applications"
  ON job_applications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ユーザーは申し込みを更新可能
CREATE POLICY "Users can update job applications"
  ON job_applications FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 8. chat 関連テーブル
-- ============================================================
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can access chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Authenticated users can access chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Authenticated users can access chat members" ON chat_room_members;

CREATE POLICY "Authenticated users can read chat rooms"
  ON chat_rooms FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create chat rooms"
  ON chat_rooms FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can read chat messages"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can send chat messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can read chat members"
  ON chat_room_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can join chat rooms"
  ON chat_room_members FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================
-- 9. AI関連テーブル
-- ============================================================
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can access own ai conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users can access own ai messages" ON ai_conversation_messages;
DROP POLICY IF EXISTS "Users can access own ai logs" ON ai_chat_logs;

CREATE POLICY "Users can access own ai conversations"
  ON ai_conversations FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can access own ai messages"
  ON ai_conversation_messages FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can access own ai logs"
  ON ai_chat_logs FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 10. その他テーブル
-- ============================================================
ALTER TABLE video_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can manage video views" ON video_views;
DROP POLICY IF EXISTS "Authenticated users can manage content reports" ON content_reports;
DROP POLICY IF EXISTS "Anyone can create inquiries" ON inquiries;

CREATE POLICY "Authenticated users can manage video views"
  ON video_views FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can manage content reports"
  ON content_reports FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can create inquiries"
  ON inquiries FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Authenticated users can read inquiries"
  ON inquiries FOR SELECT
  TO authenticated
  USING (true);
