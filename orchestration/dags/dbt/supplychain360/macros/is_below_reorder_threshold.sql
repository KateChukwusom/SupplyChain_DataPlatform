-- macros/is_below_reorder_threshold.sql

{% macro is_below_reorder_threshold(quantity_col, threshold_col) %}
    case
        when {{ quantity_col }} <= {{ threshold_col }} then true
        else false
    end
{% endmacro %}

