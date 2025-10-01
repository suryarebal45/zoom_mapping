
-- Participants referencing non-existent Meetings
SELECT 
    P.PARTICIPANT_ID,
    P.MEETING_ID,
    'Missing meeting reference' AS TEST_FAILURE_REASON
FROM {{ ref('bz_participants') }} P
LEFT JOIN {{ ref('bz_meetings') }} M
  ON P.MEETING_ID = M.MEETING_ID
WHERE M.MEETING_ID IS NULL

UNION ALL

-- Participants referencing non-existent Users
SELECT 
    P.PARTICIPANT_ID,
    P.USER_ID,
    'Missing user reference' AS TEST_FAILURE_REASON
FROM {{ ref('bz_participants') }} P
LEFT JOIN {{ ref('bz_users') }} U
  ON P.USER_ID = U.USER_ID
WHERE U.USER_ID IS NULL
