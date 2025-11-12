-- ===========================================
-- supermarket_db seed.sql
-- ===========================================

-- カテゴリ
INSERT INTO master.categories (category_name, description) VALUES
('Beverages', 'Soft drinks, coffees, teas, beers, and ales'),
('Snacks', 'Chips, nuts, and other snack foods'),
('Dairy', 'Cheese, milk, and other dairy products'),
('Produce', 'Fruits and vegetables'),
('Meat', 'Fresh and processed meats');

-- サプライヤ
INSERT INTO master.suppliers (supplier_name, contact_name, phone, email, address, city, country) VALUES
('FreshFarm Foods', 'Alice Kim', '03-1111-2222', 'alice@freshfarm.com', '1-2-3 Tokyo', 'Tokyo', 'Japan'),
('Nippon Beverages', 'Taro Sato', '03-3333-4444', 'taro@nipbev.jp', '2-3-4 Yokohama', 'Kanagawa', 'Japan'),
('Hokkaido Dairy Co.', 'Yuki Tanaka', '011-555-6666', 'yuki@hokkaidodairy.jp', '5-6-7 Sapporo', 'Hokkaido', 'Japan');

-- 商品
INSERT INTO master.products (product_name, category_id, supplier_id, unit_price, cost_price) VALUES
('Green Tea Bottle 500ml', 1, 2, 150, 80),
('Potato Chips 100g', 2, 1, 120, 60),
('Whole Milk 1L', 3, 3, 180, 100),
('Cheddar Cheese 200g', 3, 3, 450, 280),
('Banana (1pc)', 4, 1, 80, 40),
('Apple (1pc)', 4, 1, 120, 70),
('Ground Beef 500g', 5, 1, 600, 400),
('Chicken Breast 500g', 5, 1, 550, 350),
('Oolong Tea Bottle 500ml', 1, 2, 160, 85),
('Chocolate Bar 50g', 2, 1, 130, 65);

-- 店舗
INSERT INTO master.stores (store_name, address, city, phone) VALUES
('Tokyo Central Store', '1-1-1 Marunouchi', 'Tokyo', '03-1000-1000'),
('Osaka Namba Store', '2-2-2 Namba', 'Osaka', '06-2000-2000');

-- 従業員
INSERT INTO master.employees (store_id, first_name, last_name, position, hire_date, salary) VALUES
(1, 'Ken', 'Yamada', 'Manager', '2020-04-01', 450000),
(1, 'Mika', 'Suzuki', 'Cashier', '2021-06-10', 280000),
(2, 'Ryo', 'Tanaka', 'Manager', '2019-03-15', 460000),
(2, 'Aya', 'Kobayashi', 'Cashier', '2022-02-01', 270000);

-- 顧客
INSERT INTO master.customers (first_name, last_name, email, phone, city) VALUES
('Takeshi', 'Ito', 'takeshi@example.com', '090-1234-5678', 'Tokyo'),
('Yumi', 'Okada', 'yumi@example.com', '090-2345-6789', 'Osaka'),
('Hiroshi', 'Nakamura', 'hiroshi@example.com', '090-3456-7890', 'Tokyo'),
('Keiko', 'Fujita', 'keiko@example.com', '090-4567-8901', 'Kyoto');

-- 在庫（初期値）
INSERT INTO inventory.stock_levels (store_id, product_id, quantity) VALUES
(1, 1, 100),
(1, 2, 150),
(1, 3, 80),
(1, 4, 50),
(1, 5, 120),
(1, 6, 100),
(1, 7, 40),
(1, 8, 60),
(2, 1, 90),
(2, 9, 70),
(2, 10, 130);

-- 仕入 (purchases)
INSERT INTO transactions.purchases (supplier_id, employee_id, store_id, total_amount) VALUES
(1, 1, 1, 50000),
(2, 3, 2, 75000),
(3, 1, 1, 60000);

-- 販売 (sales)
INSERT INTO transactions.sales (customer_id, employee_id, store_id, payment_method, total_amount) VALUES
(1, 2, 1, 'cash', 980),
(2, 4, 2, 'credit', 1320),
(3, 2, 1, 'mobile', 1680);

-- 販売明細 (sale_items)
INSERT INTO transactions.sale_items (sale_id, product_id, quantity, unit_price, discount) VALUES
(1, 1, 2, 150, 0),
(1, 2, 3, 120, 10),
(2, 9, 2, 160, 0),
(2, 10, 4, 130, 0),
(3, 3, 2, 180, 0),
(3, 5, 3, 80, 0);

-- 在庫更新を反映（販売トリガーで減算される想定）
-- （トリガーが無効なら以下を有効化）
-- UPDATE inventory.stock_levels
-- SET quantity = quantity - 5
-- WHERE product_id IN (1,2,3,5,9,10);

