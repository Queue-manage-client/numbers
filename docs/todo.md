# TODO

## 完了した項目（2026-05-08）

[x] 動画投稿時のサムネイルプレビュー → `Image.memory` で bytes プレビュー表示に置き換え
[x] 求人応募時のバリデーション → `job_repository.applyJob` で求人存在 + `status='open'` + 重複応募チェック
[x] インターン投稿/編集時の日付範囲チェック → 終了日 < 開始日を弾く
[x] 動画アップロード時のファイルサイズチェック → 200MB 上限 + SnackBar 警告
[x] チャットルーム作成時の企業所属確認 → RLS で `profiles.company_id == chat_rooms.company_id` を強制
[x] 企業ロゴアップロード機能 → 既に実装済（記録が古かった）
[x] インターン編集・更新・削除 → 既に実装済（記録が古かった）
[x] 企業チャットルーム取得 → 既に実装済（記録が古かった）
[x] 環境変数バリデーション → 既に実装済（StateError throw）
[x] デバッグ用 print 文 → 約 30 箇所 → 2 箇所まで削減済

## 残課題

[ ] エラーハンドリングの改善：catch ブロックで `rethrow` / `debugPrint` のみの箇所が残存（213 箇所）。Network/DB エラー時のユーザー通知が抜ける箇所を機能別に絞って改善する（別フェーズ）

## 再確認の結果（2026-05-08）

[x] インターン詳細ページの表示：「建築・土木」「関西」「ハードコード」等のリテラルなし → **既に修正済み**
[x] 企業プロフィール編集のロゴ表示：選択時 `Image.memory(bytes)` / 既存 `Image.network(url)` / 未選択時 `Icons.business` で適切に分岐済 → **既に修正済み**

## セキュリティ：RLS 強化（2026-05-08 完了）

`USING/WITH CHECK が true` の緩い INSERT/UPDATE/DELETE ポリシーをすべて発見・修正：

[x] `chat_rooms` INSERT/UPDATE/DELETE → 自社のみ（migration 20260504000007）
[x] `chat_messages` INSERT → 自分がメンバーの room のみ（migration 20260504000008）
[x] `chat_room_members` INSERT → 自分自身 OR 自社の room
[x] `chat_room_members` DELETE → 自分自身 OR 自社の room
[x] `companies` INSERT → 未所属 user のみ（既に企業に所属しているユーザーは追加で会社を作れない）

確認 SQL：`pg_policy` に `polqual='true' OR polwithcheck='true'` の INSERT/UPDATE/DELETE ポリシーが **0 件**（pg_policy 全件チェック済み）。

## サブスクリプション機能（2026-05-08 リリース可能状態）

[x] 企業向けサブスク基盤（Stripe + Supabase Webhook）一式
[x] 商工会・特別プランの申請審査フロー（admin 側 UI 含む）
[x] 投稿系画面の `can_company_post()` ガード（`approval_status='approved'` AND `subscription_status IN ('active','trialing')`）
