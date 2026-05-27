-- ============================================================
-- Objetivo: Realizar verificações iniciais na camada raw,
--           avaliando volume, unicidade, datas e nulos.
-- Fonte: raw_superstore
-- ============================================================


-- ============================================================
-- 1. Volume e unicidade dos principais identificadores
-- ============================================================

SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT row_id) AS row_ids_distintos,
    COUNT(DISTINCT order_id) AS pedidos_distintos,
    COUNT(DISTINCT customer_id) AS clientes_distintos,
    COUNT(DISTINCT product_id) AS produtos_distintos
FROM raw_superstore;


-- ============================================================
-- 2. Intervalo das datas na base bruta
-- ============================================================
-- Nesta etapa, as datas ainda estão armazenadas como texto,
-- pois a camada raw preserva o dado como veio do CSV.
-- A conversão para DATE será feita na camada staging.

SELECT
    MIN(order_date) AS menor_order_date,
    MAX(order_date) AS maior_order_date,
    MIN(ship_date) AS menor_ship_date,
    MAX(ship_date) AS maior_ship_date
FROM raw_superstore;


-- ============================================================
-- 3. Verificação de nulos em campos críticos
-- ============================================================

SELECT
    COUNT(*) AS total_linhas,
    COUNT(*) FILTER (WHERE order_date IS NULL OR order_date = '') AS order_date_nula,
    COUNT(*) FILTER (WHERE ship_date IS NULL OR ship_date = '') AS ship_date_nula,
    COUNT(*) FILTER (WHERE sales IS NULL) AS sales_nula,
    COUNT(*) FILTER (WHERE profit IS NULL) AS profit_nulo,
    COUNT(*) FILTER (WHERE customer_id IS NULL OR customer_id = '') AS customer_id_nulo,
    COUNT(*) FILTER (WHERE product_id IS NULL OR product_id = '') AS product_id_nulo
FROM raw_superstore;