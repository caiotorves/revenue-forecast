-- ============================================================
-- Objetivo: Criar o modelo dimensional a partir da staging,
--           com dimensões, tabela fato e validações principais.
-- Fonte: stg_sales_orders
-- ============================================================


-- ============================================================
-- 1. Dimensão de clientes
-- ============================================================

CREATE TABLE dim_customer (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(50) NOT NULL
);

INSERT INTO dim_customer (
    customer_id,
    customer_name,
    segment
)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM stg_sales_orders;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT customer_id) AS clientes_distintos,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicidades_customer_id
FROM dim_customer;


-- ============================================================
-- 2. Dimensão de produtos
-- ============================================================

DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    product_name TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_product UNIQUE (
        product_id,
        product_name,
        category,
        sub_category
    )
);

INSERT INTO dim_product (
    product_id,
    product_name,
    category,
    sub_category
)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    sub_category
FROM stg_sales_orders;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT product_key) AS product_keys_distintas,
    COUNT(DISTINCT product_id) AS product_ids_distintos,
    COUNT(DISTINCT product_id || '|' || product_name || '|' || category || '|' || sub_category) AS combinacoes_produto_distintas,
    COUNT(*) - COUNT(DISTINCT product_key) AS duplicidades_product_key,
    COUNT(*) - COUNT(DISTINCT product_id || '|' || product_name || '|' || category || '|' || sub_category) AS duplicidades_combinacao_produto
FROM dim_product;


-- ============================================================
-- 3. Dimensão de localização
-- ============================================================

DROP TABLE IF EXISTS dim_location;

CREATE TABLE dim_location (
    location_key SERIAL PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    CONSTRAINT uq_dim_location UNIQUE (
        country,
        region,
        state,
        city,
        postal_code
    )
);

INSERT INTO dim_location (
    country,
    region,
    state,
    city,
    postal_code
)
SELECT DISTINCT
    country,
    region,
    state,
    city,
    postal_code
FROM stg_sales_orders;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT location_key) AS location_keys_distintas,
    COUNT(DISTINCT country || '|' || region || '|' || state || '|' || city || '|' || COALESCE(postal_code, 'SEM_POSTAL_CODE')) AS combinacoes_location_distintas,
    COUNT(*) - COUNT(DISTINCT location_key) AS duplicidades_location_key,
    COUNT(*) - COUNT(DISTINCT country || '|' || region || '|' || state || '|' || city || '|' || COALESCE(postal_code, 'SEM_POSTAL_CODE')) AS duplicidades_combinacao_location
FROM dim_location;


-- ============================================================
-- 4. Dimensão de envio
-- ============================================================

CREATE TABLE dim_shipping (
    shipping_key SERIAL PRIMARY KEY,
    ship_mode VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_shipping UNIQUE (ship_mode)
);

INSERT INTO dim_shipping (
    ship_mode
)
SELECT DISTINCT
    ship_mode
FROM stg_sales_orders;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT shipping_key) AS shipping_keys_distintas,
    COUNT(DISTINCT ship_mode) AS ship_modes_distintos,
    COUNT(*) - COUNT(DISTINCT shipping_key) AS duplicidades_shipping_key,
    COUNT(*) - COUNT(DISTINCT ship_mode) AS duplicidades_ship_mode
FROM dim_shipping;


-- ============================================================
-- 5. Dimensão calendário
-- ============================================================

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    year_month VARCHAR(7) NOT NULL,
    month_start DATE NOT NULL
);

INSERT INTO dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    year_month,
    month_start
)
WITH date_bounds AS (
    SELECT
        LEAST(MIN(order_date), MIN(ship_date))::DATE AS start_date,
        GREATEST(MAX(order_date), MAX(ship_date))::DATE AS end_date
    FROM stg_sales_orders
),
date_list AS (
    SELECT
        (start_date + day_number)::DATE AS full_date
    FROM date_bounds,
    GENERATE_SERIES(
        0,
        end_date - start_date
    ) AS day_number
)
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INT AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::INT AS year,
    EXTRACT(QUARTER FROM full_date)::INT AS quarter,
    EXTRACT(MONTH FROM full_date)::INT AS month,
    TRIM(TO_CHAR(full_date, 'Month')) AS month_name,
    TO_CHAR(full_date, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', full_date)::DATE AS month_start
FROM date_list;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT date_key) AS date_keys_distintas,
    COUNT(DISTINCT full_date) AS full_dates_distintas,
    MIN(full_date) AS primeira_data,
    MAX(full_date) AS ultima_data,
    COUNT(*) - COUNT(DISTINCT date_key) AS duplicidades_date_key,
    COUNT(*) - COUNT(DISTINCT full_date) AS duplicidades_full_date
FROM dim_date;


-- ============================================================
-- 6. Tabela fato de vendas
-- ============================================================

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
    sales_key SERIAL PRIMARY KEY,

    row_id INT NOT NULL,
    order_id VARCHAR(50) NOT NULL,

    order_date_key INT NOT NULL,
    ship_date_key INT NOT NULL,

    customer_id VARCHAR(20) NOT NULL,
    product_key INT NOT NULL,
    location_key INT NOT NULL,
    shipping_key INT NOT NULL,

    sales NUMERIC(12, 2) NOT NULL,
    quantity INT NOT NULL,
    discount NUMERIC(5, 2) NOT NULL,
    profit NUMERIC(12, 2) NOT NULL,
    estimated_cost NUMERIC(12, 2) NOT NULL,
    profit_margin NUMERIC(10, 4),
    days_to_ship INT NOT NULL,

    CONSTRAINT uq_fact_sales_row UNIQUE (row_id),

    CONSTRAINT fk_fact_sales_order_date
        FOREIGN KEY (order_date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_fact_sales_ship_date
        FOREIGN KEY (ship_date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key),

    CONSTRAINT fk_fact_sales_location
        FOREIGN KEY (location_key)
        REFERENCES dim_location(location_key),

    CONSTRAINT fk_fact_sales_shipping
        FOREIGN KEY (shipping_key)
        REFERENCES dim_shipping(shipping_key)
);

INSERT INTO fact_sales (
    row_id,
    order_id,
    order_date_key,
    ship_date_key,
    customer_id,
    product_key,
    location_key,
    shipping_key,
    sales,
    quantity,
    discount,
    profit,
    estimated_cost,
    profit_margin,
    days_to_ship
)
SELECT
    s.row_id,
    s.order_id,

    TO_CHAR(s.order_date, 'YYYYMMDD')::INT AS order_date_key,
    TO_CHAR(s.ship_date, 'YYYYMMDD')::INT AS ship_date_key,

    s.customer_id,
    p.product_key,
    l.location_key,
    sh.shipping_key,

    s.sales,
    s.quantity,
    s.discount,
    s.profit,
    s.estimated_cost,
    s.profit_margin,
    s.days_to_ship
FROM stg_sales_orders s
JOIN dim_product p
    ON s.product_id = p.product_id
   AND s.product_name = p.product_name
   AND s.category = p.category
   AND s.sub_category = p.sub_category
JOIN dim_location l
    ON s.country = l.country
   AND s.region = l.region
   AND s.state = l.state
   AND s.city = l.city
   AND COALESCE(s.postal_code, 'SEM_POSTAL_CODE') = COALESCE(l.postal_code, 'SEM_POSTAL_CODE')
JOIN dim_shipping sh
    ON s.ship_mode = sh.ship_mode;

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT sales_key) AS sales_keys_distintas,
    COUNT(DISTINCT row_id) AS row_ids_distintos,
    COUNT(*) - COUNT(DISTINCT sales_key) AS duplicidades_sales_key,
    COUNT(*) - COUNT(DISTINCT row_id) AS duplicidades_row_id,
    SUM(sales) AS receita_total,
    SUM(profit) AS lucro_total
FROM fact_sales;