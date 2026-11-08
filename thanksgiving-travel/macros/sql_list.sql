{# Renders a list var as a SQL tuple, e.g. [2020, 2025] -> (2020, 2025) #}
{% macro sql_list(values) -%}
    ({{ values | join(', ') }})
{%- endmacro %}
