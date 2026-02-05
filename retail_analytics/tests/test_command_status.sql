
-- Vérifie que le statut est bien dans la liste attendue
select
    order_id,
    order_status
FROM {{ ref('stg_orders') }} O
WHERE O.order_status NOT IN ('pending', 'shipped', 'cancelled', 'completed')

