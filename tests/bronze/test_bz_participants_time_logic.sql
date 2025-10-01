{{ config(severity = 'error') }}

SELECT
    PARTICIPANT_ID,
    JOIN_TIME,
    LEAVE_TIME,
    'Leave time before join time' AS TEST_FAILURE_REASON
FROM {{ ref('bz_participants') }}
WHERE LEAVE_TIME IS NOT NULL 
  AND LEAVE_TIME < JOIN_TIME
