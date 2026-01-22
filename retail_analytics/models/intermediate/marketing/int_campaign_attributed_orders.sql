{{
    config(
        materialized='view',
        schema='intermediate'
    )
}}

WITH web_events AS (
    SELECT *
    FROM {{ ref('stg_web_event') }}
    WHERE event_type = 'page_view'
    AND campaign_id IS NOT NULL
),

orders AS (
    SELECT *
    FROM {{ ref('stg_orders') }}
    WHERE order_status = 'completed'
),

joined AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.total_amount,
        o.net_amount,
        we.campaign_id,
        we.event_timestamp AS last_campaign_touch,
        ROW_NUMBER() OVER (
            PARTITION BY o.order_id
            ORDER BY we.event_timestamp DESC
        ) AS rn
    FROM orders o
    LEFT JOIN web_events we
        ON we.customer_id = o.customer_id
        AND we.event_timestamp <= o.order_date
        AND we.event_timestamp >= o.order_date - INTERVAL '7 days'
),

final AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        total_amount,
        net_amount,
        campaign_id,
        last_campaign_touch,
        CASE 
            WHEN campaign_id IS NOT NULL THEN 
                net_amount * 0.05 
        END AS cost_attribution
    FROM joined
    QUALIFY rn = 1 OR rn IS NULL
)

SELECT * FROM final