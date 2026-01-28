{{
    config(
            materialized='view',
            schema='intermediate'
)
}}

WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),
orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
    WHERE order_status = 'completed'
),
products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
product_sales AS (
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    p.cost_price,
    p.retail_price,
    p.margin_per_unit,
    count(DISTINCT oi.order_id) AS orders_count,
    sum(oi.quantity) AS units_sold,
    coalesce(sum(oi.line_total), 0) AS total_revenue,
    coalesce(sum(oi.quantity * p.cost_price), 0) AS total_cost,
    coalesce(sum(oi.line_total - (oi.quantity * p.cost_price)), 0) AS total_profit
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_name, p.product_id, p.category, p.sub_category, p.brand, p.cost_price, p.retail_price, p.margin_per_unit
)

SELECT * FROM product_sales