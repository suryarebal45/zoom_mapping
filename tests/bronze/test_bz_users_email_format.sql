{{ config(severity = 'warn') }}

SELECT 
    USER_ID,
    EMAIL,
    'Invalid email format' AS TEST_FAILURE_REASON
FROM {{ ref('bz_users') }}
WHERE EMAIL IS NOT NULL 
  AND NOT REGEXP_LIKE(EMAIL, '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$', 'i')
