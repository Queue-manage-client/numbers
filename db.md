# Numbers Database Schema

**Project:** numbers
**Region:** ap-northeast-1
**Database Version:** PostgreSQL 17.6.1.044
**Generated:** 2026-01-26

---

## Public Schema Tables

### companies
企業情報を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| name | text | NO | - | 企業名 |
| description | text | YES | - | 企業説明 |
| address | text | YES | - | 住所 |
| industry | text | YES | - | 業種 |
| website | text | YES | - | Webサイト |
| is_suspended | boolean | YES | false | 停止フラグ |
| created_at | timestamptz | YES | now() | 作成日時 |
| updated_at | timestamptz | YES | now() | 更新日時 |

**RLS:** Enabled
**Rows:** 9

---

### profiles
ユーザープロファイルを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | - | Primary Key (auth.usersへのFK) |
| role | text | NO | - | ロール ('user', 'company_user', 'admin') |
| company_id | uuid | YES | - | 所属企業ID |
| position | text | YES | - | 役職 |
| department | text | YES | - | 部署 |
| nickname | text | YES | - | ニックネーム |
| gender | text | YES | - | 性別 |
| birth_date | date | YES | - | 生年月日 |
| location | text | YES | - | 所在地 |
| university | text | YES | - | 大学 |
| skills | text[] | YES | - | スキル |
| job_preferences | jsonb | YES | - | 就職希望条件 |
| is_suspended | boolean | YES | false | アカウント停止フラグ |
| chat_suspended | boolean | YES | false | チャット停止フラグ |
| created_at | timestamptz | YES | now() | 作成日時 |
| updated_at | timestamptz | YES | now() | 更新日時 |

**RLS:** Enabled
**Rows:** 9
**Foreign Keys:**
- `id` → `auth.users.id`
- `company_id` → `companies.id`

---

### jobs
求人情報を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| company_id | uuid | NO | - | 企業ID |
| title | text | NO | - | 求人タイトル |
| description | text | YES | - | 求人説明 |
| salary | text | YES | - | 給与 |
| location | geography | YES | - | 勤務地（地理情報） |
| status | text | YES | 'open' | ステータス ('open', 'closed') |
| created_at | timestamptz | YES | now() | 作成日時 |
| updated_at | timestamptz | YES | now() | 更新日時 |

**RLS:** Enabled
**Rows:** 6
**Foreign Keys:**
- `company_id` → `companies.id`

---

### job_applications
求人応募を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| job_id | uuid | NO | - | 求人ID |
| user_id | uuid | NO | - | ユーザーID |
| status | text | YES | 'applied' | ステータス ('applied', 'messaging', 'rejected', 'accepted') |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 0
**Foreign Keys:**
- `job_id` → `jobs.id`
- `user_id` → `profiles.id`

---

### internships
インターンシップ情報を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| company_id | uuid | NO | - | 企業ID |
| title | text | NO | - | タイトル |
| description | text | YES | - | 説明 |
| start_date | date | YES | - | 開始日 |
| end_date | date | YES | - | 終了日 |
| tags | text[] | YES | - | タグ |
| is_public | boolean | YES | true | 公開フラグ |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 10
**Foreign Keys:**
- `company_id` → `companies.id`

---

### company_videos
企業動画を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| company_id | uuid | NO | - | 企業ID |
| video_path | text | NO | - | 動画パス |
| thumbnail_path | text | YES | - | サムネイルパス |
| title | text | YES | - | タイトル |
| description | text | YES | - | 説明 |
| vertical | boolean | YES | true | 縦型動画フラグ |
| is_public | boolean | YES | true | 公開フラグ |
| sort_order | integer | YES | 0 | 並び順 |
| tags | text[] | YES | '{}' | タグ |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 11
**Foreign Keys:**
- `company_id` → `companies.id`

---

### chat_rooms
チャットルームを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| name | text | NO | - | ルーム名 |
| description | text | YES | - | 説明 |
| room_type | text | YES | - | タイプ ('direct', 'group') |
| company_id | uuid | YES | - | 企業ID |
| created_at | timestamptz | YES | now() | 作成日時 |
| updated_at | timestamptz | YES | now() | 更新日時 |

**RLS:** Enabled
**Rows:** 5
**Foreign Keys:**
- `company_id` → `companies.id`

---

### chat_room_members
チャットルームメンバーを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| room_id | uuid | NO | - | Primary Key (複合) |
| profile_id | uuid | NO | - | Primary Key (複合) |
| joined_at | timestamptz | YES | now() | 参加日時 |

**RLS:** Enabled
**Rows:** 5
**Foreign Keys:**
- `room_id` → `chat_rooms.id`
- `profile_id` → `profiles.id`

---

### chat_messages
チャットメッセージを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| room_id | uuid | NO | - | ルームID |
| profile_id | uuid | NO | - | プロファイルID |
| content | text | NO | - | メッセージ内容 |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 10
**Foreign Keys:**
- `room_id` → `chat_rooms.id`
- `profile_id` → `profiles.id`

---

### ai_chat_logs
AIチャットログを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| profile_id | uuid | NO | - | プロファイルID |
| question | text | NO | - | 質問 |
| answer | text | YES | - | 回答 |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 0
**Foreign Keys:**
- `profile_id` → `profiles.id`

---

### inquiries
問い合わせを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| profile_id | uuid | NO | - | プロファイルID |
| subject | text | NO | - | 件名 |
| message | text | NO | - | メッセージ |
| status | text | YES | 'open' | ステータス ('open', 'progress', 'resolved') |
| created_at | timestamptz | YES | now() | 作成日時 |

**RLS:** Enabled
**Rows:** 0
**Foreign Keys:**
- `profile_id` → `profiles.id`

---

### banned_words
禁止ワードを管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| word | text | NO | - | 禁止ワード (Unique) |
| created_by | uuid | YES | - | 作成者ID |
| created_at | timestamp | YES | now() | 作成日時 |

**RLS:** Disabled
**Rows:** 0
**Foreign Keys:**
- `created_by` → `profiles.id`

---

### content_reports
コンテンツ通報を管理するテーブル

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | NO | uuid_generate_v4() | Primary Key |
| reporter_id | uuid | NO | - | 通報者ID |
| content_type | text | NO | - | コンテンツタイプ |
| content_id | uuid | NO | - | コンテンツID |
| reason | text | NO | - | 理由 |
| description | text | YES | - | 詳細説明 |
| status | text | YES | 'pending' | ステータス |
| admin_notes | text | YES | - | 管理者メモ |
| resolved_at | timestamp | YES | - | 解決日時 |
| resolved_by | uuid | YES | - | 解決者ID |
| created_at | timestamp | YES | now() | 作成日時 |

**RLS:** Disabled
**Rows:** 0
**Foreign Keys:**
- `reporter_id` → `profiles.id`
- `resolved_by` → `profiles.id`

---

## ER Diagram (Text)

```
┌─────────────────┐       ┌─────────────────┐
│   auth.users    │       │    companies    │
│─────────────────│       │─────────────────│
│ id (PK)         │◄──────│ id (PK)         │
│ email           │       │ name            │
│ ...             │       │ description     │
└────────┬────────┘       │ is_suspended    │
         │                └────────┬────────┘
         │                         │
         ▼                         │
┌─────────────────┐                │
│    profiles     │◄───────────────┘
│─────────────────│
│ id (PK/FK)      │
│ role            │
│ company_id (FK) │
│ nickname        │
│ is_suspended    │
└────────┬────────┘
         │
    ┌────┴────┬────────────┬───────────────┐
    │         │            │               │
    ▼         ▼            ▼               ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│job_apps  │ │inquiries │ │ai_chat   │ │chat_room │
│          │ │          │ │_logs     │ │_members  │
└──────────┘ └──────────┘ └──────────┘ └────┬─────┘
    │                                       │
    ▼                                       ▼
┌──────────┐                         ┌──────────┐
│  jobs    │                         │chat_rooms│
│          │                         │          │
└────┬─────┘                         └────┬─────┘
     │                                    │
     │                                    ▼
     │                               ┌──────────┐
     │                               │chat_msgs │
     │                               └──────────┘
     ▼
┌──────────┐    ┌──────────┐    ┌──────────┐
│companies │───▶│internship│    │company   │
│          │───▶│          │    │_videos   │
│          │───▶└──────────┘    └──────────┘
└──────────┘
```

---

## Storage Buckets

| Bucket Name | Type | Public | Rows |
|-------------|------|--------|------|
| (4 buckets) | STANDARD | - | 4 |

**Objects:** 2

---

## Notes

- すべてのpublicスキーマテーブルでRLSが有効化されています（banned_wordsとcontent_reportsを除く）
- 地理情報拡張（PostGIS）が有効で、`jobs.location`でgeography型を使用
- UUIDはすべて`extensions.uuid_generate_v4()`で自動生成
