-- ============================================================
-- 01_create_database.sql
-- Projeto: Revenue Forecast - Clube Candeias
-- Objetivo: Criar a tabela raw para armazenar os dados brutos
--           importados do arquivo Sample Superstore.
-- ============================================================

DROP TABLE IF EXISTS raw_superstore;

CREATE TABLE raw_superstore (
    row_id INT,
    order_id TEXT,
    order_date TEXT,
    ship_date TEXT,
    ship_mode TEXT,
    customer_id TEXT,
    customer_name TEXT,
    segment TEXT,
    country TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    region TEXT,
    product_id TEXT,
    category TEXT,
    sub_category TEXT,
    product_name TEXT,
    sales NUMERIC(12,2),
    quantity INT,
    discount NUMERIC(5,2),
    profit NUMERIC(12,2)
);

-- Verificação inicial da carga
SELECT COUNT(*) AS total_rows
FROM raw_superstore;

SELECT *
FROM raw_superstore
LIMIT 10;