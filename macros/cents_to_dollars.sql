{% macro cents_to_dollars(column_name, scale=2) -%}
    cast({{ column_name }} / 100.0 as decimal(12, {{ scale }}))
{%- endmacro %}
