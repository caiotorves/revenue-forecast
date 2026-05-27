-- ============================================================
-- Objetivo: Criar views analíticas para acompanhamento de receita,
--           rentabilidade, clientes, pedidos e base mensal de forecast.
-- Fonte: modelo dimensional
-- ============================================================


-- ============================================================
-- 1. Receita mensal
-- ============================================================

CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    d.month_start,
    d.year,
    d.month,
    d.year_month,
    SUM(f.sales) AS monthly_revenue,
    SUM(f.profit) AS monthly_profit,
    SUM(f.estimated_cost) AS monthly_estimated_cost,
    SUM(f.quantity) AS monthly_quantity,
    AVG(f.discount) AS avg_discount,
    COUNT(DISTINCT f.order_id) AS orders_count,
    COUNT(DISTINCT f.customer_id) AS customers_count,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS monthly_profit_margin
FROM dim_date d
JOIN fact_sales f
    ON d.date_key = f.order_date_key
GROUP BY
    d.month_start,
    d.year,
    d.month,
    d.year_month;

-- Validação: amostra da view
SELECT *
FROM vw_monthly_revenue
ORDER BY month_start;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    COUNT(*) AS rows_count,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(DISTINCT customer_id) AS customers_count
FROM fact_sales

UNION ALL

SELECT
    'vw_monthly_revenue' AS source,
    COUNT(*) AS rows_count,
    SUM(monthly_revenue) AS total_revenue,
    SUM(monthly_profit) AS total_profit,
    SUM(monthly_estimated_cost) AS total_estimated_cost,
    SUM(monthly_quantity) AS total_quantity,
    SUM(orders_count) AS orders_count,
    NULL AS customers_count
FROM vw_monthly_revenue;


-- ============================================================
-- 2. Receita por segmento de cliente
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_by_segment AS
SELECT
    c.segment,
    SUM(f.sales) AS total_revenue,
    SUM(f.profit) AS total_profit,
    SUM(f.estimated_cost) AS total_estimated_cost,
    SUM(f.quantity) AS total_quantity,
    AVG(f.discount) AS avg_discount,
    COUNT(DISTINCT f.order_id) AS orders_count,
    COUNT(DISTINCT f.customer_id) AS customers_count,
    SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id), 0) AS avg_order_value,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS segment_profit_margin
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_id = c.customer_id
GROUP BY
    c.segment;

-- Validação: amostra da view
SELECT *
FROM vw_revenue_by_segment
ORDER BY total_revenue DESC;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(DISTINCT customer_id) AS customers_count
FROM fact_sales

UNION ALL

SELECT
    'vw_revenue_by_segment' AS source,
    SUM(total_revenue) AS total_revenue,
    SUM(total_profit) AS total_profit,
    SUM(total_estimated_cost) AS total_estimated_cost,
    SUM(total_quantity) AS total_quantity,
    SUM(orders_count) AS orders_count,
    SUM(customers_count) AS customers_count
FROM vw_revenue_by_segment;


-- ============================================================
-- 3. Receita por categoria
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_by_category AS
SELECT
    p.category,
    p.sub_category,
    SUM(f.sales) AS total_revenue,
    SUM(f.profit) AS total_profit,
    SUM(f.estimated_cost) AS total_estimated_cost,
    SUM(f.quantity) AS total_quantity,
    AVG(f.discount) AS avg_discount,
    COUNT(DISTINCT f.order_id) AS orders_count,
    COUNT(DISTINCT p.product_id) AS products_count,
    SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id), 0) AS avg_order_value,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS category_profit_margin
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.category,
    p.sub_category;

-- Validação: amostra da view
SELECT *
FROM vw_revenue_by_category
ORDER BY total_revenue DESC;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS orders_count
FROM fact_sales

UNION ALL

SELECT
    'vw_revenue_by_category' AS source,
    SUM(total_revenue),
    SUM(total_profit),
    SUM(total_estimated_cost),
    SUM(total_quantity),
    SUM(orders_count)
FROM vw_revenue_by_category;


-- ============================================================
-- 4. Receita por região
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_by_region AS
SELECT
    l.region,
    l.state,
    l.city,
    SUM(f.sales) AS total_revenue,
    SUM(f.profit) AS total_profit,
    SUM(f.estimated_cost) AS total_estimated_cost,
    SUM(f.quantity) AS total_quantity,
    AVG(f.discount) AS avg_discount,
    COUNT(DISTINCT f.order_id) AS orders_count,
    COUNT(DISTINCT f.customer_id) AS customers_count,
    SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id), 0) AS avg_order_value,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS region_profit_margin
FROM fact_sales f
JOIN dim_location l
    ON f.location_key = l.location_key
GROUP BY
    l.region,
    l.state,
    l.city;

-- Validação: amostra da view
SELECT *
FROM vw_revenue_by_region
ORDER BY total_revenue DESC;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity
FROM fact_sales

UNION ALL

SELECT
    'vw_revenue_by_region' AS source,
    SUM(total_revenue),
    SUM(total_profit),
    SUM(total_estimated_cost),
    SUM(total_quantity)
FROM vw_revenue_by_region;


-- ============================================================
-- 5. Métricas por pedido
-- ============================================================

CREATE OR REPLACE VIEW vw_order_metrics AS
SELECT
    f.order_id,
    f.customer_id,
    f.order_date_key,
    SUM(f.sales) AS order_revenue,
    SUM(f.profit) AS order_profit,
    SUM(f.estimated_cost) AS order_estimated_cost,
    SUM(f.quantity) AS order_quantity,
    COUNT(*) AS order_lines_count,
    COUNT(DISTINCT f.product_key) AS distinct_products_count,
    AVG(f.discount) AS avg_discount,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS order_profit_margin
FROM fact_sales f
GROUP BY
    f.order_id,
    f.customer_id,
    f.order_date_key;

-- Validação: amostra da view
SELECT *
FROM vw_order_metrics
ORDER BY order_revenue DESC;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS orders_count
FROM fact_sales

UNION ALL

SELECT
    'vw_order_metrics' AS source,
    SUM(order_revenue),
    SUM(order_profit),
    SUM(order_estimated_cost),
    SUM(order_quantity),
    COUNT(order_id)
FROM vw_order_metrics;


-- ============================================================
-- 6. Receita por cliente
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_revenue AS
SELECT
    c.customer_id,
    c.customer_name,
    c.segment,
    SUM(f.sales) AS total_revenue,
    SUM(f.profit) AS total_profit,
    SUM(f.estimated_cost) AS total_estimated_cost,
    SUM(f.quantity) AS total_quantity,
    COUNT(DISTINCT f.order_id) AS orders_count,
    SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id), 0) AS avg_order_value,
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS customer_profit_margin
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.segment;

-- Validação: amostra da view
SELECT *
FROM vw_customer_revenue
ORDER BY total_revenue DESC;

-- Validação: comparação dos totais com a tabela fato
SELECT
    'fact_sales' AS source,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(estimated_cost) AS total_estimated_cost,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_id) AS customers_count
FROM fact_sales

UNION ALL

SELECT
    'vw_customer_revenue' AS source,
    SUM(total_revenue),
    SUM(total_profit),
    SUM(total_estimated_cost),
    SUM(total_quantity),
    COUNT(customer_id)
FROM vw_customer_revenue;


-- ============================================================
-- 7. Base mensal para forecast em Python
-- ============================================================

CREATE OR REPLACE VIEW vw_forecast_base_monthly AS
SELECT
    month_start,
    year,
    month,
    year_month,
    monthly_revenue,
    monthly_profit,
    monthly_estimated_cost,
    monthly_quantity,
    avg_discount,
    orders_count,
    customers_count,
    monthly_profit_margin
FROM vw_monthly_revenue;

-- Validação: amostra da view
SELECT *
FROM vw_forecast_base_monthly
ORDER BY month_start;

-- Validação: comparação dos totais com a view mensal
SELECT
    'vw_monthly_revenue' AS source,
    COUNT(*) AS rows_count,
    SUM(monthly_revenue) AS total_revenue,
    SUM(monthly_profit) AS total_profit,
    SUM(monthly_estimated_cost) AS total_estimated_cost,
    SUM(monthly_quantity) AS total_quantity
FROM vw_monthly_revenue

UNION ALL

SELECT
    'vw_forecast_base_monthly' AS source,
    COUNT(*) AS rows_count,
    SUM(monthly_revenue),
    SUM(monthly_profit),
    SUM(monthly_estimated_cost),
    SUM(monthly_quantity)
FROM vw_forecast_base_monthly;