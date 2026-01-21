{{
config(
materialized='view',
schema='intermediate'
)
}}

WITH customer_orders as (
SELECT * FROM {{ ref('int_customers_orders') }}
),
customer_metrics AS (
SELECT
    customer_id,
    count(DISTINCT order_id) AS total_orders,
    count(
        DISTINCT 
        case 
            WHEN order_channel = 'web' 
            THEN order_id END) AS web_orders,
    count(
        DISTINCT 
        case 
            WHEN order_channel = 'mobile' 
            THEN order_id END) AS mobile_orders,   

    sum(net_amount) AS lifetime_value, 
    avg(net_amount) AS avg_order_value,
    sum(
        case 
            WHEN order_channel = 'web' 
            THEN net_amount else 0 END) AS web_revenue,
    sum(
        case 
            WHEN order_channel = 'mobile' 
            THEN net_amount else 0 END) AS mobile_revenue,
    
    min(order_date) AS first_order_date,
    max(order_date) AS last_order_date,
    datediff('day', min(order_date), max(order_date)) AS customer_tenure_days

FROM customer_orders
WHERE order_id IS NOT NULL
GROUP BY customer_id
)

SELECT * FROM customer_metrics