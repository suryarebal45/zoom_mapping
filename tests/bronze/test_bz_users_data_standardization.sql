{{ config(severity = 'warn') }}

SELECT
    USER_ID,
    PLAN_TYPE,
    USER_NAME,
    'Data not standardized' AS TEST_FAILURE_REASON
FROM {{ ref('bz_users') }}
WHERE 
    PLAN_TYPE != UPPER(TRIM(PLAN_TYPE))
    OR USER_NAME != TRIM(USER_NAME)
