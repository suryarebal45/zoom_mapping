{{ config(severity = 'error') }}

SELECT
    MEETING_ID,
    DURATION_MINUTES,
    'Invalid duration' AS TEST_FAILURE_REASON
FROM {{ ref('bz_meetings') }}
WHERE DURATION_MINUTES < 0 
   OR DURATION_MINUTES > 1440
