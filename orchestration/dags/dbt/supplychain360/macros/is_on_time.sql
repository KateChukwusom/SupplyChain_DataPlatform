-- Purpose: Returns true if delivered on or before expected
--          date, false if late, null if still pending


{% macro is_on_time(actual_date, expected_date) %}
    case
        when {{ actual_date }} is null                then null
        when {{ actual_date }} <= {{ expected_date }} then true
        else                                               false
    end
{% endmacro %}
