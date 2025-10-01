-- Validate organization size categorization
WITH org_user_counts AS (
    SELECT 
        company,
        COUNT(DISTINCT user_id) AS user_count
    FROM {{ source('silver', 'sv_users') }}
    WHERE company IS NOT NULL 
      AND TRIM(company) != ''
      AND record_status = 'VALID'
    GROUP BY company
),
expected_sizes AS (
    SELECT 
        company,
        user_count,
        CASE 
            WHEN user_count <= 10 THEN 'Small (1-10)'
            WHEN user_count <= 50 THEN 'Medium (11-50)'
            WHEN user_count <= 200 THEN 'Large (51-200)'
            ELSE 'Enterprise (200+)'
        END AS expected_size
    FROM org_user_counts
)
SELECT 
    god.organization_name,
    god.organization_size as actual_size,
    es.expected_size
FROM {{ ref('go_organization_dimension') }} god
JOIN expected_sizes es 
  ON god.organization_name = es.company
WHERE god.organization_size != es.expected_size
