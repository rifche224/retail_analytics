
-- Vérifie que le statut est bien dans la liste attendue
select
    order_id,
    order_status
from {{ ref('stg_orders') }}
where order_status not in ('pending', 'shipped', 'cancelled', 'completed')

