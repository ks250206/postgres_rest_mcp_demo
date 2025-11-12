-- ===========================================
-- supermarket_db : roles.sql
-- ===========================================

-- 1️⃣  アプリケーション接続用ロール（ログイン可）
CREATE ROLE appuser WITH
  LOGIN
  PASSWORD 'secret'
  NOSUPERUSER
  NOCREATEDB
  NOCREATEROLE
  NOINHERIT
  CONNECTION LIMIT -1;

-- 2️⃣  匿名アクセス用ロール（PostgREST用）
CREATE ROLE web_anon NOLOGIN;

-- 3️⃣  MCP / PostgREST 用の基本権限
GRANT USAGE ON SCHEMA master, transactions, inventory TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA master, transactions, inventory TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA master, transactions, inventory TO appuser;

-- 4️⃣  PostgREST の匿名用ロールに読み取りだけ許可（必要に応じて）
GRANT USAGE ON SCHEMA master, transactions, inventory TO web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA master, transactions, inventory TO web_anon;

-- 5️⃣  新しいテーブルが追加された時にも自動で権限が付与されるよう設定
ALTER DEFAULT PRIVILEGES IN SCHEMA master, transactions, inventory
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

ALTER DEFAULT PRIVILEGES IN SCHEMA master, transactions, inventory
  GRANT SELECT ON TABLES TO web_anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA master, transactions, inventory
  GRANT USAGE, SELECT ON SEQUENCES TO appuser;

-- 6️⃣  PostgREST がアプリケーションロールとして接続するための設定例
--     (PostgREST の設定ファイルまたは環境変数で指定)
-- PGRST_DB_URI=postgres://appuser:secret@postgres:5432/supermarket_db
-- PGRST_DB_ANON_ROLE=web_anon
-- PGRST_DB_SCHEMA=master,transactions,inventory

