-- スキーマ作成
CREATE SCHEMA IF NOT EXISTS master;
CREATE SCHEMA IF NOT EXISTS transactions;
CREATE SCHEMA IF NOT EXISTS inventory;

-- ========================
-- マスタ系テーブル
-- ========================

CREATE TABLE master.categories (
  category_id SERIAL PRIMARY KEY,
  category_name TEXT NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE master.suppliers (
  supplier_id SERIAL PRIMARY KEY,
  supplier_name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  country TEXT
);

CREATE TABLE master.products (
  product_id SERIAL PRIMARY KEY,
  product_name TEXT NOT NULL,
  category_id INT REFERENCES master.categories(category_id),
  supplier_id INT REFERENCES master.suppliers(supplier_id),
  unit_price NUMERIC(10,2) NOT NULL,
  cost_price NUMERIC(10,2),
  discontinued BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE master.stores (
  store_id SERIAL PRIMARY KEY,
  store_name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  phone TEXT
);

CREATE TABLE master.employees (
  employee_id SERIAL PRIMARY KEY,
  store_id INT REFERENCES master.stores(store_id),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  position TEXT,
  hire_date DATE,
  salary NUMERIC(10,2)
);

CREATE TABLE master.customers (
  customer_id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  city TEXT,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================
-- 取引系テーブル
-- ========================

CREATE TABLE transactions.purchases (
  purchase_id SERIAL PRIMARY KEY,
  supplier_id INT REFERENCES master.suppliers(supplier_id),
  employee_id INT REFERENCES master.employees(employee_id),
  store_id INT REFERENCES master.stores(store_id),
  purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  total_amount NUMERIC(12,2)
);

CREATE TABLE transactions.sales (
  sale_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES master.customers(customer_id),
  employee_id INT REFERENCES master.employees(employee_id),
  store_id INT REFERENCES master.stores(store_id),
  sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment_method TEXT CHECK (payment_method IN ('cash','credit','mobile','other')),
  total_amount NUMERIC(12,2)
);

CREATE TABLE transactions.sale_items (
  sale_item_id SERIAL PRIMARY KEY,
  sale_id INT REFERENCES transactions.sales(sale_id) ON DELETE CASCADE,
  product_id INT REFERENCES master.products(product_id),
  quantity INT NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  discount NUMERIC(5,2) DEFAULT 0,
  subtotal NUMERIC(12,2) GENERATED ALWAYS AS ((quantity * unit_price) - discount) STORED
);

-- ========================
-- 在庫テーブル
-- ========================

CREATE TABLE inventory.stock_levels (
  stock_id SERIAL PRIMARY KEY,
  store_id INT REFERENCES master.stores(store_id),
  product_id INT REFERENCES master.products(product_id),
  quantity INT DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 在庫更新トリガー（販売・仕入れ時に自動反映する例）
CREATE OR REPLACE FUNCTION inventory.update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE inventory.stock_levels
  SET quantity = quantity - NEW.quantity,
      last_updated = CURRENT_TIMESTAMP
  WHERE product_id = NEW.product_id AND store_id = (
    SELECT store_id FROM transactions.sales WHERE sale_id = NEW.sale_id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_stock_after_sale
AFTER INSERT ON transactions.sale_items
FOR EACH ROW EXECUTE FUNCTION inventory.update_stock_on_sale();

-- ========================
-- インデックス
-- ========================
CREATE INDEX idx_products_name ON master.products(product_name);
CREATE INDEX idx_sales_date ON transactions.sales(sale_date);
CREATE INDEX idx_stock_product ON inventory.stock_levels(product_id);

