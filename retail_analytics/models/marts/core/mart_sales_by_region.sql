{{
config(
        materialized='incremental',
        schema='marts_core',
        unique_key=['region', 'sales_month']
)
}}

WITH sales_data AS (
    SELECT
        o.order_id,
        o.order_date,
        o.total_amount,
        c.country as region
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref ('stg_customers') }} c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'completed'
), regional_sales AS (
    SELECT
        region,
        DATE_TRUNC('month', order_date) AS sales_month,
        SUM(total_amount) AS total_sales,
        COUNT(DISTINCT order_id) AS total_orders
    FROM sales_data
    GROUP BY region, sales_month
)

SELECT
    region,
    sales_month,
    total_sales,
    total_orders,
    current_timestamp AS _dbt_updated_at
FROM regional_sales 