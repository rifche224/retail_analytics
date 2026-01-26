{{ 
  config(
    materialized='view',
    schema='intermediate'
  ) 
}}

{%- set order_channels = ['web', 'mobile'] -%}

WITH customer_orders AS (
    SELECT *
    FROM {{ ref('int_customers_orders') }}
),

customer_metrics AS (

SELECT
    customer_id,

    count(DISTINCT order_id) AS total_orders,

    {% for channel in order_channels %}
    count(
        DISTINCT case 
            WHEN order_channel = '{{ channel }}'
            THEN order_id
        END
    ) AS {{ channel }}_orders
    {%- if not loop.last %},{% endif %}
    {% endfor %},

    sum(net_amount) AS lifetime_value,
    avg(net_amount) AS avg_order_value,

    {% for channel in order_channels %}
    sum(
        case 
            WHEN order_channel = '{{ channel }}'
            THEN net_amount
            ELSE 0
        END
    ) AS {{ channel }}_revenue
    {%- if not loop.last %},{% endif %}
    {% endfor %},

    min(order_date) AS first_order_date,
    max(order_date) AS last_order_date,
    datediff(
        'day',
        min(order_date),
        max(order_date)
    ) AS customer_tenure_days

FROM customer_orders
WHERE order_id IS NOT NULL
GROUP BY customer_id

)

SELECT *
FROM customer_metrics