-- macros/delivery_delay_days.sql

{% macro delay_in_days(expected_col, actual_col) %}
    datediff(day, {{ expected_col }}, {{ actual_col }})
{% endmacro %}