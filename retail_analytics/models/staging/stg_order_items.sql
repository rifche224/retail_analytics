{{
config(
materialized='view'
)
}}
WITH source as (
SELECT * FROM {{ source('raw_retail', 'raw_order_items') }}
),
renamed as (
SELECT
item_id,
order_id,
product_id,
quantity,
-- Prices
{{ cents_to_euros('unit_price_cents') }} as unit_price,
{{ cents_to_euros('unit_price_cents * quantity') }} as line_total,
current_timestamp as _dbt_loaded_at
FROM source
)
SELECT * FROM renamed