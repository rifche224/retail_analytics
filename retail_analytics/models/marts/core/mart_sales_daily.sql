{{
    config(
        materialized='incremental',
        unique_key='date_day',
        schema='marts_core',
        on_schema_change='append_new_columns'
)
}}

{%- set order_channels = ['web', 'mobile', 'store'] -%}

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
    
    {% for channel in order_channels %}
    count(
        DISTINCT 
            CASE 
                WHEN order_channel = '{{ channel }}' 
                THEN order_id 
                END) AS {{ channel }}_orders
    {%- if not loop.last %},{% endif %}
    {% endfor %},
    
    -- Revenue metrics
    sum(total_amount) AS total_revenue,
    sum(net_amount) AS net_revenue,
    sum(shipping_cost) AS total_shipping_revenue,
    avg(net_amount) AS avg_order_value,
    
    {% for channel in order_channels %}
    sum(
        CASE 
            WHEN order_channel = '{{ channel }}' 
            THEN net_amount ELSE 0 END) AS {{ channel }}_revenue
    {%- if not loop.last %},{% endif %}
    {% endfor %},
    
    current_timestamp AS _dbt_updated_at
FROM orders
GROUP BY order_date
)
SELECT * FROM daily_metrics
