SELECT 
    RECORD_TABLE,
    RECORD_ID,
    'Invalid timestamp' AS TEST_FAILURE_REASON
FROM (
    SELECT 'bz_meetings' AS RECORD_TABLE, MEETING_ID AS RECORD_ID, START_TIME AS TS
    FROM {{ ref('bz_meetings') }}
    UNION ALL
    SELECT 'bz_meetings', MEETING_ID, END_TIME
    FROM {{ ref('bz_meetings') }}
    UNION ALL
    SELECT 'bz_participants', PARTICIPANT_ID, JOIN_TIME
    FROM {{ ref('bz_participants') }}
    UNION ALL
    SELECT 'bz_participants', PARTICIPANT_ID, LEAVE_TIME
    FROM {{ ref('bz_participants') }}
) t
WHERE TS IS NULL
