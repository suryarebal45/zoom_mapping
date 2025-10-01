-- Validate audit records are created for model executions
WITH expected_models AS (
    SELECT model_name FROM VALUES
        ('go_user_dimension'),
        ('go_time_dimension'),
        ('go_organization_dimension'),
        ('go_device_dimension'),
        ('go_geography_dimension')
    AS t(model_name)
)
SELECT 
    em.model_name
FROM expected_models em
LEFT JOIN {{ ref('process_audit') }} pa 
    ON em.model_name = pa.pipeline_name 
    AND DATE(pa.start_time) = CURRENT_DATE()
WHERE pa.pipeline_name IS NULL
