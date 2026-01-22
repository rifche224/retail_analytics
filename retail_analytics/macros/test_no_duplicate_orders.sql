{% test test_no_duplicate_orders(model, column_name) %}

SELECT
    {{ column_name }},
    COUNT(*) AS nb_rows
FROM {{ model }}
GROUP BY {{ column_name }}
HAVING COUNT(*) > 1

{% endtest %}