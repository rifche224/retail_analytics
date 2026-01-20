{{
config(
materialized='view'
)
}}

WITH source as (
SELECT * FROM {{ source('raw_retail', 'raw_products') }}
),
renamed as (
SELECT
product_id,
product_name,
category,
sub_category,
brand,
-- Prices
{{ cents_to_euros('cost_price_cents') }} as cost_price,
{{ cents_to_euros('retail_price_cents') }} as retail_price,
{{ cents_to_euros('retail_price_cents - cost_price_cents') }} as margin_per_unit,
round(
((retail_price_cents - cost_price_cents)::decimal / retail_price_cents) * 100,
2
) as margin_percentage,
current_timestamp as _dbt_loaded_at
FROM source
)
SELECT * FROM renamed