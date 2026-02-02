-- Test simple pour vérifier le workflow CI
-- Ce test vérifie qu'il n'y a pas de commandes avec un montant négatif

SELECT
    order_id,
    total_amount
FROM {{ ref('stg_orders') }}
WHERE total_amount < 0
