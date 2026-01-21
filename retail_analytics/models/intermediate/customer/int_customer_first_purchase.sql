{{
config(
materialized='view',
schema='intermediate'
)
}}

WITH customer_orders as (
SELECT * FROM {{ ref('int_customers_orders') }}
),
first_purchases as (
SELECT
    customer_id,
    min(order_date) as first_order_date,
    min(
        case 
            WHEN order_channel = 'web' 
            THEN order_date 
            END) as first_web_order_date,
    min(
        case 
            WHEN order_channel = 'mobile' 
            THEN order_date 
            END) as first_mobile_order_date
            
FROM customer_orders
WHERE order_id IS NOT NULL
GROUP BY customer_id
)

SELECT * FROM first_purchases