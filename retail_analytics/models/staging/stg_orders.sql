{{ config(
    materialized='view'
) }}

WITH source as (
SELECT * FROM {{ source('raw_retail', 'raw_orders') }}
    WHERE order_id IS NOT NULL
    AND customer_id IS NOT NULL
),
renamed AS (
    SELECT
    order_id,
    customer_id,
    order_date::date as order_date,
    lower(order_channel) as order_channel,
    lower(order_status) as order_status,
    {{ cents_to_euros('total_amount_cents') }} as total_amount,
    {{ cents_to_euros('shipping_cost_cents') }} as shipping_cost,
    {{ cents_to_euros('total_amount_cents - shipping_cost_cents') }} as net_amount,
    current_timestamp as _dbt_loaded_at
FROM source
)

SELECT * FROM renamed