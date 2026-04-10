-- company_videosに求人紐付け用のjob_idカラムを追加
ALTER TABLE company_videos ADD COLUMN job_id UUID REFERENCES jobs(id) ON DELETE SET NULL;

-- 検索パフォーマンス用インデックス
CREATE INDEX idx_company_videos_job_id ON company_videos(job_id);
