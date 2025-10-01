-- Validate that license join returns the latest license per user
WITH latest_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type,
        ROW_NUMBER() OVER (
            PARTITION BY assigned_to_user_id 
            ORDER BY start_date DESC, load_timestamp DESC
        ) as rn
    FROM {{ source('silver', 'sv_licenses') }}
    WHERE record_status = 'VALID'
),
expected_licenses AS (
    SELECT 
        assigned_to_user_id,
        license_type
    FROM latest_licenses
    WHERE rn = 1
)
SELECT 
    gud.user_id,
    gud.license_type as actual_license,
    el.license_type as expected_license
FROM {{ ref('go_user_dimension') }} gud
JOIN expected_licenses el 
  ON gud.user_id = el.assigned_to_user_id
WHERE COALESCE(gud.license_type, 'No License') != COALESCE(el.license_type, 'No License')
