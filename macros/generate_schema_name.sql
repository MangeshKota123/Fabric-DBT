{# Use the custom schema as-is (default dbt behaviour prefixes the target schema, giving dbo_dbt_silver). #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name is not none else target.schema }}
{%- endmacro %}
