# フォルダー構造ドキュメント

## プロジェクト全体の構成

```
lib/
├── core/                    # アプリ全体で共有される基盤機能
│   ├── config/             # 設定ファイル
│   ├── constants/          # 定数定義
│   ├── theme/              # テーマ設定
│   └── router/             # ルーティング設定
├── features/               # 機能ごとのモジュール
│   ├── auth/              # 認証機能
│   └── home/              # ホーム画面
└── shared/                # 複数の機能で共有されるコード
    ├── widgets/           # 共通ウィジェット
    └── utils/             # ユーティリティ関数
```

---

## 各フォルダーの詳細

### `lib/core/` - コア機能

アプリケーション全体で使用される基盤となる機能を配置します。

#### `core/config/`
- **用途**: アプリの設定ファイル
- **例**:
  - `supabase_config.dart` - Supabaseの接続情報（.envから読み込み）
  - API設定、環境変数の読み込みなど

#### `core/constants/`
- **用途**: アプリ全体で使用する定数
- **例**:
  - `app_constants.dart` - アプリ名、バージョンなど
  - エラーメッセージ、デフォルト値など

#### `core/theme/`
- **用途**: アプリのデザインテーマ
- **例**:
  - `app_theme.dart` - カラースキーム、フォント、スタイル定義
  - 現在は #323232 と #fff のカラースキームを使用

#### `core/router/`
- **用途**: アプリ全体のルーティング（画面遷移）設定
- **例**:
  - `app_router.dart` - GoRouterを使用したルート定義
  - パス、ページ、遷移アニメーションなど

---

### `lib/features/` - 機能モジュール

各機能ごとに独立したモジュールとして管理します。Clean Architectureベースの構造です。

#### 機能モジュールの構造（例: `features/auth/`）

```
auth/
├── data/
│   └── repositories/      # データ取得・保存のロジック
├── domain/               # ビジネスロジック（必要に応じて）
│   ├── entities/        # エンティティ（データモデル）
│   └── usecases/        # ユースケース（ビジネスルール）
└── presentation/         # UI層
    ├── pages/           # 画面
    ├── widgets/         # 画面内の部品
    └── providers/       # 状態管理（Riverpod）
```

**各層の役割**:

- **`data/`**: 外部データソース（Supabase、API）とのやり取り
  - `repositories/` - データの取得・保存処理を実装

- **`domain/`**: ビジネスロジック（必要な場合のみ作成）
  - `entities/` - アプリで扱うデータモデル
  - `usecases/` - ビジネスルール

- **`presentation/`**: ユーザーに表示する部分
  - `pages/` - 画面全体
  - `widgets/` - 画面を構成する部品
  - `providers/` - Riverpodを使った状態管理

**現在実装されている機能**:

##### `features/auth/` - 認証機能
- **用途**: ユーザーのサインアップ、ログイン、ログアウト
- **主要ファイル**:
  - `data/repositories/auth_repository.dart` - Supabaseを使った認証処理
  - `presentation/providers/auth_provider.dart` - 認証状態の管理

##### `features/home/` - ホーム画面
- **用途**: アプリのメイン画面
- **主要ファイル**:
  - `presentation/pages/home_page.dart` - ホーム画面のUI

---

### `lib/shared/` - 共有コード

複数の機能で共通して使用するコードを配置します。

#### `shared/widgets/`
- **用途**: 複数の画面で使い回すウィジェット
- **例**:
  - カスタムボタン
  - ローディングインジケーター
  - 共通ヘッダー/フッター

#### `shared/utils/`
- **用途**: ユーティリティ関数
- **例**:
  - 日付フォーマット
  - バリデーション関数
  - ヘルパー関数

---

## 新しい機能を追加する場合

1. `lib/features/` に新しいフォルダーを作成（例: `features/profile/`）
2. 必要に応じて `data/`, `domain/`, `presentation/` を作成
3. `core/router/app_router.dart` にルートを追加
4. 状態管理が必要な場合は `presentation/providers/` を作成

---

## ベストプラクティス

- **単一責任の原則**: 各ファイルは1つの責任だけを持つ
- **機能ごとに分離**: 機能は `features/` 内で独立して管理
- **再利用性**: 共通コードは `shared/` に配置
- **命名規則**: ファイル名はスネークケース（`auth_repository.dart`）
- **フォルダー構造**: 深くなりすぎないように注意（最大3-4階層）

---

## 状態管理（Riverpod）

- **Provider の配置場所**: `presentation/providers/`
- **種類**:
  - `Provider` - 不変の値
  - `StateProvider` - シンプルな状態
  - `StateNotifierProvider` - 複雑な状態管理
  - `StreamProvider` - ストリームベースの状態

---

## ルーティング（GoRouter）

- **設定場所**: `core/router/app_router.dart`
- **使い方**: `context.go('/path')` で画面遷移
- **パス例**:
  - `/` - ホーム画面
  - `/login` - ログイン画面
  - `/profile` - プロフィール画面

---

## Supabase連携

- **設定**: `core/config/supabase_config.dart`
- **環境変数**: `.env` ファイルに `SUPABASE_URL` と `SUPABASE_ANON_KEY` を設定
- **使用方法**: `Supabase.instance.client` でアクセス
- **認証**: `features/auth/data/repositories/auth_repository.dart` で実装

---

## 次のステップ

1. `flutter pub get` を実行してパッケージをインストール
2. `flutter run -d web-server` でウェブサーバーを起動
3. 新しい機能を追加する場合は `features/` にモジュールを作成
