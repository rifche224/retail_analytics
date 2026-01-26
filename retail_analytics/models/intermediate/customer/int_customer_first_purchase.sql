{{
config(
materialized='view',
schema='intermediate'
)
}}

{%- set order_channels = ['web', 'mobile'] -%}

WITH customer_orders as (
SELECT * FROM {{ ref('int_customers_orders') }}
),
first_purchases as (
SELECT
    customer_id,
    min(order_date) as first_order_date,
    
    {% for channel in order_channels %}
    min(
        case 
            WHEN order_channel = '{{ channel }}' 
            THEN order_date 
            END) as first_{{ channel }}_order_date
    {%- if not loop.last %},{% endif %}
    {% endfor %}
            
FROM customer_orders
WHERE order_id IS NOT NULL
GROUP BY customer_id
)

SELECT * FROM first_purchases
