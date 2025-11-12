# Supermarket REST Stack

PostgreSQL 17 をベースにした小売 / スーパーマーケット向けデータベースと、PostgREST による即席 REST API、そして MCP 対応の `postgres-mcp` をワンコマンドで立ち上げる構成です。スキーマ、サンプルデータ、アプリ用ロールが自動的に投入されるため、分析・プロトタイピングや API 実験のベースとして利用できます。

## 構成

| サービス        | 役割                                                         | ポート |
| --------------- | ------------------------------------------------------------ | ------ |
| `postgres`      | スキーマ / シード投入済みの PostgreSQL 17                    | 5432   |
| `postgres-mcp`  | PostgreSQL を MCP(Server-Sent Events) にブリッジするサービス | 8000   |
| `postgrest_api` | PostgREST(devel) による REST API                             | 3000   |

### ディレクトリ

```
├── compose.yml                # docker compose 定義
├── data/                      # 永続化される PGDATA（初回起動時に自動生成）
└── postgres/
    ├── postgresql.conf        # 任意の追加設定（空のままでも可）
    └── initdb.d/
        ├── 1_schema.sql       # スキーマ・テーブル定義
        ├── 2_seed.sql         # マスタ / トランザクションのシードデータ
        └── 3_roles.sql        # アプリケーションロールと権限
```

## 必要要件

- Docker 24.x 以降
- Docker Compose V2（`docker compose` コマンドが使えること）

## クイックスタート

1. 環境変数を必要に応じて調整します（未変更なら `cp .env.example .env` でデフォルトを利用）。

   ```bash
   cp .env.example .env
   ```

2. レポジトリ直下でコンテナを起動します。

   ```bash
   docker compose -f compose.yml up -d
   ```

3. ヘルスチェックが通るまで待機します（`postgres` が healthy になると `postgres-mcp` と `postgrest_api` が起動）。

   ```bash
   docker compose ps
   ```

4. PostgREST からテーブルを参照できます。

   ```bash
   curl "http://localhost:3000/products?select=*"

   curl "http://localhost:3000/stock_levels" \
   -H "Accept-Profile: inventory"
   ```

   デフォルト接続情報: `postgresql://appuser:secret@localhost:5432/supermarket_db`

## スキーマ概要

- `master` スキーマ: `categories`, `suppliers`, `products`, `stores`, `employees`, `customers`
- `transactions` スキーマ: `purchases`, `sales`, `sale_items`
- `inventory` スキーマ: `stock_levels` と販売後に在庫を減算するトリガー `inventory.update_stock_on_sale`

サンプルデータは `2_seed.sql` で投入され、PostgREST から即座に参照・更新できます。

## 環境変数

`.env` を用意すると `compose.yml` の `${POSTGRES_*}` 変数が自動的に読み込まれます（`docker compose` は `.env` を同じディレクトリから参照します）。

| 変数                | 役割                                             | デフォルト       |
| ------------------- | ------------------------------------------------ | ---------------- |
| `POSTGRES_USER`     | DB 管理ユーザ（`postgres` サービスの superuser） | `postgres`       |
| `POSTGRES_PASSWORD` | 上記ユーザのパスワード                           | `password`       |
| `POSTGRES_DB`       | 初期作成 DB 名（スキーマ・シード投入先）         | `supermarket_db` |

PostgREST / MCP から参照される `DATABASE_URI` や `PGRST_DB_URI` はこれらの値をもとに組み立てられます。値を変更した場合は `data/` ディレクトリを削除してから再作成してください。

## PostgREST / MCP の利用

### PostgREST

- エンドポイント: `http://localhost:3000`
- 対象スキーマ: `master,transactions,inventory`
- 接続ロール: `appuser`（`3_roles.sql` で CRUD 権限を付与済み）
- 例: `curl "http://localhost:3000/transactions.sales?select=sale_id,total_amount"` で販売一覧を取得

### postgres-mcp（MCP 詳細）

- SSE エンドポイント: `http://localhost:8000/sse`
- 内部接続: `DATABASE_URI=postgresql://appuser:secret@postgres:5432/${POSTGRES_DB}`（Compose 内ネットワークで解決）
- アクセスモード: Compose では `--access-mode=unrestricted`。読み取り専用にしたい場合は `compose.yml` のコマンドを `--access-mode=restricted` に差し替えてください。
- トランスポート: `--transport=sse` のため、Claude Desktop や VS Code MCP クライアントの SSE 設定から接続できます。

#### MCP クライアント設定例（Claude Desktop）

Claude Desktop の `claude_desktop_config.json` に以下を追加すると、SSE で `postgres-mcp` に接続できます。

```jsonc
{
  "mcpServers": {
    "supermarket-db": {
      "transport": "sse",
      "url": "http://localhost:8000/sse"
    }
  }
}
```

接続後は MCP クライアントが公開する `list_tables`, `describe_table`, `run_sql` などのアクション（実装は `postgres-mcp` イメージに依存）を通じて PostgreSQL に問い合わせできます。SSE 経由で DB に到達できる分、アクセスモードを restricted にして読み取り専用ツールとして運用するのが安全です。

## よく使うコマンド

```bash
# ログ確認
docker compose logs -f postgres

# サービス停止
docker compose down

# すべてのボリュームも削除
docker compose down -v
```

## データのリセット

データを再初期化したい場合は `data/` ディレクトリを削除し、再度 `docker compose up` を実行してください。既存の `data/` が残っていると `initdb.d` の SQL は再実行されません。

```bash
rm -rf data
docker compose -f compose.yml up -d
```

## トラブルシューティング

- `postgres` が起動しない / `exit code 1`: `data/` に古いクラスタが残っている可能性があります。バックアップ後に削除して再起動してください。
- PostgREST で 401 が返る: `PGRST_DB_URI` の資格情報が `appuser/secret` から変更されていないか確認してください。
- ポート競合: `compose.yml` の `ports` セクションでホスト側ポートを任意の値に変更できます。

## ライセンス

本リポジトリは MIT ライセンスのもとで公開されています。
