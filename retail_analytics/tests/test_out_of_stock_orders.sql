-- Test d'identification des commandes avec des produits en rupture de stock
SELECT
    o.order_id,
    p.product_id,
    i.reorder_point
FROM {{ ref('stg_orders') }} o
JOIN {{ ref('stg_order_items') }} oi ON o.order_id = oi.order_id
JOIN {{ ref('stg_products') }} p ON oi.product_id = p.product_id
JOIN {{ ref('stg_inventory') }} i ON p.product_id = i.product_id
WHERE i.reorder_point <= 0