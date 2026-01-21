{{
    config(
        materialized='view',
        schema='staging'
    )
}}
WITH source AS (
    SELECT * FROM {{ source('raw_retail', 'raw_web_events') }}
),
renamed AS (
    SELECT
        event_id,
        customer_id,
        event_timestamp::timestamp AS event_timestamp,
        lower(event_type) AS event_type,
        campaign_id,
        product_id,
        current_timestamp AS _dbt_loaded_at
    FROM source
)
SELECT * FROM renamed