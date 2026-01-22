{{
    config(
        materialized='table',
        schema='marts_marketing'
    )
}}

WITH campaigns AS (
    SELECT * 
    FROM {{ ref('stg_marketing_campaigns') }}
),

attributed_orders AS (
    SELECT * 
    FROM {{ ref('int_campaign_attributed_orders') }}
),

campaign_metrics AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        c.channel AS campaign_channel_type,
        c.start_date,
        c.end_date,
        c.budget,
        COALESCE(COUNT(DISTINCT ao.order_id), 0) AS total_attributed_orders,
        COALESCE(SUM(ao.net_amount), 0) AS total_revenue,
        COALESCE(SUM(ao.net_amount) - SUM(ao.cost_attribution), 0) AS total_profit,
        CASE
            WHEN COALESCE(SUM(ao.cost_attribution), 0) = 0 THEN 0
            ELSE ROUND(((SUM(ao.net_amount) - SUM(ao.cost_attribution)) / SUM(ao.cost_attribution)) * 100, 2)
        END AS roi_percentage,
        current_timestamp AS _dbt_updated_at
    FROM campaigns c
    LEFT JOIN attributed_orders ao ON c.campaign_id = ao.campaign_id
    GROUP BY c.campaign_id, c.campaign_name, c.channel, c.start_date, c.end_date, c.budget
)

SELECT * FROM campaign_metrics