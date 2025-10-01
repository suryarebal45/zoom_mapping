{% macro test_dimension_completeness(model, source_table, join_key) %}

SELECT 
    s.{{ join_key }}
FROM {{ source('silver', source_table) }} s
LEFT JOIN {{ ref(model) }} d 
  ON s.{{ join_key }} = d.{{ join_key }}
WHERE d.{{ join_key }} IS NULL
  AND s.{{ join_key }} IS NOT NULL
  AND s.record_status = 'VALID'

{% endmacro %}
