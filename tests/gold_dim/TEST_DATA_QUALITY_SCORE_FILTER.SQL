-- Validate only high-quality records are included
SELECT 
    su.user_id,
    data_quality_score
FROM {{ source('silver', 'sv_users') }} su
JOIN {{ ref('go_user_dimension') }} gud 
  ON su.user_id = gud.user_id
WHERE su.data_quality_score < 0.7
  AND su.record_status = 'VALID'
