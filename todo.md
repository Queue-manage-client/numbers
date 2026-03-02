[x] インターン画面において、承認済みの場合、「承認済み - チャットで連絡できます」をおすとチャットページに遷移するりようにしてください。
[x] ユーザー側のホームの特集欄の一番上について、Adminが設定したバナー画像（最大10枚）が一定間隔で横に自動スクロールされながら表示されるようにしたいです。画像は1枚ずつ表示し、paddingなしで、特集/トップ/その他のタブの真下に、いかなる空白もあけず設置し、もちろん左右にもいかなる空間もあけないように広げます(全体padding等の影響も受けないように)。画像サイズは白銀比で(widthをMediaQueryで計算し、そこから白銀比になるように高さを設定する)。
[x] 上のタスクのバナーの下に、現在、企業名が表示されて、ショート動画がサムネ表示されていますが、企業名ではなく、Adminが設定した文言（おすすめ企業のような感じ）でAdminが設定した動画を表示させるように変更お願いしたいです！
例えば、一番上におすすめ企業として動画のサムネ(16:9)を横並びに並べる(このサムネは、企業側で動画投稿時に設定したもの)。タイトルはサムネの上にかぶせる感じ。その下に人気の企業として、以下同様みたいな感じにしたい。文言はAdminが決めれる。タイトルは企業が決めたやつ。

---

# 完了報告

## タスク6: インターン承認済み → チャット遷移
- **対象ファイル**: `intern_detail_page.dart`, `job_detail_page.dart`
- **変更内容**: 承認済みステータスボタンのonPressedで `context.go('/chats')` を呼び出すように変更
- **備考**: 求人詳細ページでも同様の修正を実施

## タスク7: バナーカルーセル（特集タブ上部）
- **DB**: `feed_banners` テーブル作成（id, image_url, link_url, sort_order, is_active）
- **ストレージ**: `banners` バケット作成（public）
- **Provider**: `feedBannersProvider` 追加（feed_provider.dart）
- **UI**: `_BannerCarousel` ウィジェット作成
  - タブ直下にpadding無しで配置
  - 白銀比（width / 1.414）で高さ計算
  - 4秒間隔の自動スクロール（PageView）
  - ページインジケーター（ドット）表示
- **Admin**: `AdminFeedManagementPage` にバナー管理タブを追加

## タスク8: Admin設定の特集セクション
- **DB**: `feed_sections`, `feed_section_videos` テーブル作成
- **Provider**: `feedSectionsProvider` 追加（セクション + 動画 + signed URL）
- **UI**: `_CuratedVideoSection` + `_SectionVideoCard` ウィジェット作成
  - Adminが設定した文言（例: おすすめ企業）をセクションタイトルとして表示
  - 16:9のサムネイル画像に企業が設定したタイトルをオーバーレイ表示
  - 横スクロール対応
- **Admin**: `AdminFeedManagementPage` に特集セクション管理タブを追加
  - セクション追加/編集/削除/有効切替
  - セクション内の動画追加/削除/並べ替え

## Admin管理画面
- **新規ページ**: `lib/features/admin/presentation/pages/admin_feed_management_page.dart`
- **ルート追加**: `/admin/feed` → `AdminFeedManagementPage`
- **ダッシュボード**: 「フィード管理」メニューカード追加

## マイグレーション
- `supabase/migrations/20260302010000_add_feed_banners_and_sections.sql`
  - RLSポリシー設定済み（公開読み取り + 認証ユーザー全操作）
  - インデックス作成済み
