{{
    config(
    materialized='table',
    schema='marts_customer'
)
}}

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
customer_ltv AS (
    SELECT * FROM {{ ref('int_customer_lifetime_value') }}
),
customer_profile AS (
SELECT
    c.customer_id,
    c.full_name,
    c.customer_email,
    c.country,
    c.customer_registration_date,
    c.customer_segment AS original_segment,
    coalesce(ltv.total_orders, 0) AS total_orders,
    coalesce(ltv.lifetime_value, 0) AS lifetime_value,
    coalesce(ltv.avg_order_value, 0) AS avg_order_value,
    ltv.first_order_date,
    ltv.last_order_date,
    coalesce(ltv.customer_tenure_days, 0) AS tenure_days,
    CASE
        WHEN ltv.last_order_date >= current_date - interval '30 days' THEN 'Active'
        WHEN ltv.last_order_date >= current_date - interval '90 days' THEN 'At Risk'
        WHEN ltv.last_order_date >= current_date - interval '180 days' THEN 'Dormant'
        WHEN ltv.last_order_date IS NOT NULL THEN 'Lost'
    ELSE 'Never Purchased'
    END AS recency_segment,
    CASE
        WHEN ltv.total_orders >= 10 THEN 'Champion'
        WHEN ltv.total_orders >= 5 THEN 'Loyal'
        WHEN ltv.total_orders >= 2 THEN 'Regular'
        WHEN ltv.total_orders = 1 THEN 'New'
    ELSE 'Prospect'
    END AS frequency_segment,
    CASE
        WHEN ltv.lifetime_value >= 1000 THEN 'High Value'
        WHEN ltv.lifetime_value >= 500 THEN 'Medium Value'
        WHEN ltv.lifetime_value > 0 THEN 'Low Value'
    ELSE 'No Value'
    END AS monetary_segment,
    current_timestamp AS _dbt_updated_at

FROM customers c
LEFT JOIN customer_ltv ltv ON c.customer_id = ltv.customer_id
)

SELECT * FROM customer_profile