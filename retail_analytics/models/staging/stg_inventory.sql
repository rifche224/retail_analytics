{{
    config(
        materialized='view'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw_retail', 'raw_inventory') }}
),
renamed AS (
    SELECT
        product_id,
        warehouse_location,
        quantity_available,
        reorder_point,
        last_updated,
        current_timestamp AS _dbt_loaded_at
    FROM source
)

SELECT * FROM renamed