{{ config(
    severity="error",
    
) }}

-- Your test SQL here
WITH invalid_rows AS (
    SELECT USER_ID, DATA_QUALITY_SCORE
    FROM {{ ref('sv_users') }}
    WHERE DATA_QUALITY_SCORE < 0 OR DATA_QUALITY_SCORE > 1
)
SELECT *
FROM invalid_rows
