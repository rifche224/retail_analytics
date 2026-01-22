{{
config(
materialized='table',
schema='marts_customer'
)
}}

WITH customer_orders AS (
    SELECT * FROM {{ ref('int_customers_orders') }}
),
customer_cohorts AS (
    SELECT
        customer_id,
        date_trunc('month', customer_registration_date) AS cohort_month
    FROM {{ ref('stg_customers') }}
),
order_months AS (
    SELECT DISTINCT
        customer_id,
        date_trunc('month', order_date) AS order_month
    FROM customer_orders
    WHERE order_id IS NOT NULL
),
cohort_data AS (
    SELECT
        cc.cohort_month,
        om.order_month,
        datediff('month', cc.cohort_month, om.order_month) AS months_since_registration,
        count(DISTINCT om.customer_id) AS customers
    FROM customer_cohorts cc
    LEFT JOIN order_months om ON cc.customer_id = om.customer_id
    GROUP BY cc.cohort_month, om.order_month, months_since_registration
),
cohort_sizes AS (
    SELECT
        cohort_month,
        count(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
final AS (
    SELECT
        cd.cohort_month,
        cs.cohort_size,
        cd.months_since_registration,
        cd.customers AS retained_customers,
        round((cd.customers::decimal / cs.cohort_size) * 100, 2) AS retention_rate,
        current_timestamp AS _dbt_updated_at
    FROM cohort_data cd
    JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
)
SELECT * FROM final