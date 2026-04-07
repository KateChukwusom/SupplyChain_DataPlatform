
-- Macro: delivery_status
-- Purpose: Returns On Time, Late, or Pending as a label

{% macro delivery_status(actual_date, expected_date) %}
    case
        when {{ actual_date }} is null                then 'Pending'
        when {{ actual_date }} <= {{ expected_date }} then 'On Time'
        else                                               'Late'
    end
{% endmacro %}