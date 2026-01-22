{{
    config(
        materialized='incremental',
        unique_key='date_day',
        schema='marts_core',
        on_schema_change='append_new_columns'
)
}}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
    WHERE order_status = 'completed'
    {% if is_incremental() %}
    AND order_date >= (SELECT max(date_day) FROM {{ this }})
    {% endif %}
),
daily_metrics AS (
    --order daily metrics
SELECT
    order_date AS date_day,
    count(DISTINCT order_id) AS total_orders,
    count(DISTINCT customer_id) AS unique_customers,
    count(
        DISTINCT 
            CASE 
                WHEN order_channel = 'web' 
                THEN order_id 
                END) AS web_orders,
    count(
        DISTINCT 
            CASE 
                WHEN order_channel = 'mobile' 
                THEN order_id 
                END) AS mobile_orders,
    count(
        DISTINCT 
            CASE 
                WHEN order_channel = 'store' 
                THEN order_id END) AS store_orders,
    -- Revenue metrics
    sum(total_amount) AS total_revenue,
    sum(net_amount) AS net_revenue,
    sum(shipping_cost) AS total_shipping_revenue,
    avg(net_amount) AS avg_order_value,
    sum(
        CASE 
            WHEN order_channel = 'web' 
            THEN net_amount ELSE 0 END) AS web_revenue,
    sum(
        CASE 
            WHEN order_channel = 'mobile' 
            THEN net_amount ELSE 0 END) AS mobile_revenue,
    sum(
        CASE 
            WHEN order_channel = 'store' 
            THEN net_amount ELSE 0 END) AS store_revenue,
    current_timestamp AS _dbt_updated_at
FROM orders
GROUP BY order_date
)
SELECT * FROM daily_metrics