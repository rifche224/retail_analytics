{{
    config(
        materialized='table',
        schema='marts_product'
    )
}}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
product_performance AS (
    SELECT * FROM {{ ref('int_product_performance') }}
),
inventory AS (
    SELECT
        product_id,
        sum(quantity_available) as total_stock,
        sum(reorder_point) as total_reorder_point
    FROM {{ ref('stg_inventory') }}
    GROUP BY product_id
),
final AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        p.brand,
        p.cost_price,
        p.retail_price,
        p.margin_per_unit,
        p.margin_percentage,
        coalesce(pp.units_sold, 0) AS total_units_sold,
        coalesce(pp.total_revenue, 0) AS total_revenue,
        coalesce(pp.total_profit, 0) AS total_profit,
        coalesce(pp.orders_count, 0) AS orders_count,
        coalesce(inv.total_stock, 0) AS current_stock,
        coalesce(inv.total_reorder_point, 0) AS reorder_threshold,
        case
            WHEN inv.total_stock <= inv.total_reorder_point THEN 'Low Stock'
            WHEN inv.total_stock = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status,
        case
            WHEN pp.units_sold >= 100 THEN 'Best Seller'
            WHEN pp.units_sold >= 50 THEN 'Popular'
            WHEN pp.units_sold >= 10 THEN 'Regular'
            WHEN pp.units_sold > 0 THEN 'Slow Moving'
            ELSE 'No Sales'
        END AS sales_category,
        current_timestamp AS _dbt_updated_at
FROM products p
LEFT JOIN product_performance pp ON p.product_id = pp.product_id
LEFT JOIN inventory inv ON p.product_id = inv.product_id
)

SELECT * FROM final