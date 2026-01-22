{{
    config(
        materialized='view'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw_retail', 'raw_marketing_campaigns') }}
),
renamed AS (
    SELECT
        campaign_id,
        campaign_name,
        channel,
        start_date::date AS start_date,
        end_date::date AS end_date,
        {{cents_to_euros('budget_cents')}} AS budget,
        current_timestamp AS _dbt_loaded_at
    FROM source
)

SELECT * FROM renamed