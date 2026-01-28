{% macro cents_to_euros(column_name) %}
    {% set exchange_rate = var('euro_rate', 0.85) %}
    (coalesce({{ column_name }}, 0) / 100.0) * {{ exchange_rate }}
{% endmacro %}
