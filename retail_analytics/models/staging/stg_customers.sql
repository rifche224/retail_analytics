{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT * FROM {{ source('raw_retail', 'raw_customers') }}
    WHERE customer_id IS NOT NULL
    AND email IS NOT NULL
),
renamed AS (
    SELECT DISTINCT
        customer_id,
        email AS customer_email,
        first_name,
        last_name,
        concat(first_name, ' ', last_name) AS full_name,
        country,
        registration_date::date AS customer_registration_date, 
        lower(customer_segment) AS customer_segment,
        current_timestamp AS _dbt_loaded_at
    FROM source
)

SELECT * FROM renamed