

SELECT 
    USER_ID,
    DATA_QUALITY_SCORE
FROM {{ source('silver', 'sv_users') }}
WHERE DATA_QUALITY_SCORE >= 0.7
  AND RECORD_STATUS = 'VALID'
  AND USER_ID NOT IN (
    SELECT USER_ID 
    FROM {{ ref('go_user_dimension') }}
    WHERE USER_ID IS NOT NULL
  )
