{{
config(
materialized='view',
schema='intermediate'
)
}}


WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
    WHERE order_status = 'completed'
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
joined AS (
SELECT
        c.customer_id,
        c.full_name,
        c.customer_email,
        c.customer_segment,
        c.customer_registration_date,
        o.order_id,
        o.order_date,
        o.order_channel,
        o.total_amount,
        o.shipping_cost,
        coalesce(o.net_amount, 0) AS net_amount,
        current_timestamp as _dbt_loaded_at
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
)
SELECT * FROM joined