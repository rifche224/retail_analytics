{% macro drop_ci_schema(schema_name) %}
    {% set drop_schema_sql %}
    DROP SCHEMA IF EXISTS {{ target.database }}.{{ schema_name }} CASCADE;
{% endset %}
    {% do log("Suppression du schema CI: " ~ schema_name, info=True) %}
    {% do run_query(drop_schema_sql) %}
    {% do log("CI schema supprimé avec succes", info=True) %}
{% endmacro %}
