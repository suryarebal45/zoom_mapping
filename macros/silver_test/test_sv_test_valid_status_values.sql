{% test sv_test_valid_status_values(model, column_name, valid_statuses) %}
 
WITH invalid_rows AS (
    SELECT {{ column_name }} AS STATUS
    FROM {{ model }}
    WHERE UPPER({{ column_name }}) NOT IN (
        {% for status in valid_statuses %}
            '{{ status | upper }}'{% if not loop.last %}, {% endif %}
        {% endfor %}
    )
    OR {{ column_name }} IS NULL
)
SELECT *
FROM invalid_rows
 
{% endtest %}