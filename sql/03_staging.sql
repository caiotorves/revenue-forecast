-- ============================================================
-- Objetivo: Criar a camada staging a partir da raw,
--           padronizando tipos, datas e colunas derivadas.
-- Fonte: raw_superstore
-- Saída: stg_sales_orders
-- ============================================================


-- ============================================================
-- 1. Criação da tabela staging
-- ============================================================
-- A tabela stg_sales_orders funciona como camada intermediária:
-- limpa, padroniza e deriva campos antes do modelo dimensional.

DROP TABLE IF EXISTS stg_sales_orders;

CREATE TABLE stg_sales_orders AS
SELECT
    row_id,
    order_id,

    TO_DATE(order_date, 'MM/DD/YYYY') AS order_date,
    TO_DATE(ship_date, 'MM/DD/YYYY') AS ship_date,

    TO_DATE(ship_date, 'MM/DD/YYYY') - TO_DATE(order_date, 'MM/DD/YYYY') AS days_to_ship,

    ship_mode,

    customer_id,
    customer_name,
    segment,

    country,
    city,
    state,
    postal_code,
    region,

    product_id,
    category,
    sub_category,
    product_name,

    sales,
    quantity,
    discount,
    profit,

    sales - profit AS estimated_cost,

    CASE
        WHEN sales <> 0 THEN profit / sales
        ELSE NULL
    END AS profit_margin,

    EXTRACT(YEAR FROM TO_DATE(order_date, 'MM/DD/YYYY'))::INT AS order_year,
    EXTRACT(MONTH FROM TO_DATE(order_date, 'MM/DD/YYYY'))::INT AS order_month,
    EXTRACT(QUARTER FROM TO_DATE(order_date, 'MM/DD/YYYY'))::INT AS order_quarter,
    DATE_TRUNC('month', TO_DATE(order_date, 'MM/DD/YYYY'))::DATE AS order_month_start

FROM raw_superstore;


-- ============================================================
-- 2. Validação geral da staging
-- ============================================================
-- Verifica volume, intervalo de datas e totais financeiros.

SELECT
    COUNT(*) AS total_linhas,
    MIN(order_date) AS primeira_order_date,
    MAX(order_date) AS ultima_order_date,
    MIN(ship_date) AS primeira_ship_date,
    MAX(ship_date) AS ultima_ship_date,
    SUM(sales) AS receita_total,
    SUM(profit) AS lucro_total
FROM stg_sales_orders;


-- ============================================================
-- 3. Contagem de colunas da staging
-- ============================================================

SELECT
    COUNT(*) AS total_colunas
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'stg_sales_orders';


-- ============================================================
-- 4. Validação das colunas derivadas
-- ============================================================
-- Testa prazo de entrega, margem de lucro e médias derivadas.

SELECT
    MIN(days_to_ship) AS menor_prazo_entrega,
    MAX(days_to_ship) AS maior_prazo_entrega,
    ROUND(AVG(days_to_ship), 2) AS prazo_medio_entrega,
    MIN(profit_margin) AS menor_margem,
    MAX(profit_margin) AS maior_margem,
    ROUND(AVG(profit_margin), 4) AS margem_media
FROM stg_sales_orders;


-- ============================================================
-- 5. Análise de margem por categoria e subcategoria
-- ============================================================
-- Ajuda a entender se margens negativas estão associadas
-- a desconto, categoria ou produto.

SELECT
    category,
    sub_category,
    COUNT(*) AS total_linhas,
    ROUND(SUM(sales), 2) AS receita_total,
    ROUND(SUM(profit), 2) AS lucro_total,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS margem_total,
    ROUND(AVG(discount), 4) AS desconto_medio
FROM stg_sales_orders
GROUP BY category, sub_category
ORDER BY margem_total ASC
LIMIT 10;


-- ============================================================
-- 6. Validação de consistência de clientes
-- ============================================================
-- Verifica se um mesmo customer_id aparece com nomes
-- ou segmentos diferentes.

SELECT
    customer_id,
    COUNT(DISTINCT customer_name) AS nomes_distintos,
    COUNT(DISTINCT segment) AS segmentos_distintos
FROM stg_sales_orders
GROUP BY customer_id
HAVING
    COUNT(DISTINCT customer_name) > 1
    OR COUNT(DISTINCT segment) > 1;


-- ============================================================
-- 7. Amostra da staging
-- ============================================================

SELECT *
FROM stg_sales_orders
LIMIT 50;


-- ============================================================
-- 8. Validação de consistência de produtos
-- ============================================================
-- Verifica se um mesmo product_id aparece com nomes,
-- categorias ou subcategorias diferentes.

SELECT
    product_id,
    COUNT(DISTINCT product_name) AS nomes_distintos,
    COUNT(DISTINCT category) AS categorias_distintas,
    COUNT(DISTINCT sub_category) AS subcategorias_distintas
FROM stg_sales_orders
GROUP BY product_id
HAVING
    COUNT(DISTINCT product_name) > 1
    OR COUNT(DISTINCT category) > 1
    OR COUNT(DISTINCT sub_category) > 1;


-- ============================================================
-- 9. Investigação de product_ids específicos
-- ============================================================
-- Exemplos usados para entender divergências de nomenclatura
-- entre product_id e product_name.

SELECT DISTINCT
    product_id,
    product_name
FROM stg_sales_orders
WHERE product_id = 'FUR-CH-10001146'
ORDER BY product_name;

SELECT DISTINCT
    product_id,
    product_name
FROM stg_sales_orders
WHERE product_id = 'FUR-FU-10001473'
ORDER BY product_name;

SELECT DISTINCT
    product_id,
    product_name
FROM stg_sales_orders
WHERE product_id = 'FUR-BO-10002213'
ORDER BY product_name;


-- ============================================================
-- 10. Consulta de referência dos produtos
-- ============================================================
-- Lista combinações distintas de produto, categoria e subcategoria.

SELECT DISTINCT
    product_id,
    category,
    sub_category,
    product_name
FROM stg_sales_orders
ORDER BY product_id, product_name;