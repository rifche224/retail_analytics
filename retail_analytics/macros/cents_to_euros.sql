
{% macro cents_to_euros(column_name) %}
    (coalesce({{ column_name }}, 0) / 100.0) * 0.85
{% endmacro %}
