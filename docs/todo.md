# TODO

## 未実装・不完全な機能

[] 企業ロゴアップロード機能（company_profile_edit_page.dart で「実装中」と表示されて無効化されている）
[] インターン編集・更新・削除（company_intern_edit_page.dart で Future.delayed のスタブのみ、DB操作なし）
[] 企業チャットルーム取得（company_portal_repository.dart / company_chat_repository.dart で空リスト [] を返すだけ）
[] 動画投稿時のサムネイルプレビュー（company_video_post_page.dart で「後で実装」とコメント）

## コード品質

[] デバッグ用 print 文の削除（company_dashboard_page.dart, company_video_post_page.dart, company_intern_provider.dart 等30箇所以上）
[] エラーハンドリングの改善（catch ブロックで print のみ、ユーザーへのフィードバックなし）
[] 環境変数バリデーション（supabase_config.dart で空文字を返すだけ、起動時チェックなし）

## バリデーション・セキュリティ

[] 求人応募時のバリデーション（求人の存在確認・募集中確認なし）
[] インターン投稿時の日付範囲チェック（終了日 < 開始日が可能）
[] 動画アップロード時のファイルサイズ・形式チェックなし
[] チャットルーム作成時の企業所属確認なし

## UI改善

[] インターン詳細ページのカテゴリ・エリアがハードコード（「建築・土木」「関西」固定）
[] インターン詳細ページの募集内容がハードコード
[] 企業プロフィール編集のロゴ表示がプレースホルダーアイコンのまま
