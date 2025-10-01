{% macro test_id_field_validation(model, column_name) %}
    SELECT 
        {{ column_name }},
        'Invalid ID format or value' as test_failure_reason
    FROM {{ model }}
    WHERE 
        {{ column_name }} IS NULL
        OR TRIM({{ column_name }}) = ''
        OR {{ column_name }} != TRIM({{ column_name }})
        OR LENGTH({{ column_name }}) > 255
{% endmacro %}