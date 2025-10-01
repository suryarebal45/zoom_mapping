{{ config(severity='error') }}

-- Check critical columns in Bronze tables for NULL values

WITH bz_users_nulls AS (
    SELECT
        'BZ_USERS' AS TABLE_NAME,
        COUNT(*) AS NULL_RECORDS
    FROM {{ ref('bz_users') }}
    WHERE USER_ID IS NULL OR EMAIL IS NULL OR PLAN_TYPE IS NULL
),

bz_meetings_nulls AS (
    SELECT
        'BZ_MEETINGS' AS TABLE_NAME,
        COUNT(*) AS NULL_RECORDS
    FROM {{ ref('bz_meetings') }}
    WHERE MEETING_ID IS NULL OR HOST_ID IS NULL OR START_TIME IS NULL
),

bz_participants_nulls AS (
    SELECT
        'BZ_PARTICIPANTS' AS TABLE_NAME,
        COUNT(*) AS NULL_RECORDS
    FROM {{ ref('bz_participants') }}
    WHERE PARTICIPANT_ID IS NULL OR MEETING_ID IS NULL OR USER_ID IS NULL
)

SELECT *
FROM bz_users_nulls
WHERE NULL_RECORDS > 0

UNION ALL

SELECT *
FROM bz_meetings_nulls
WHERE NULL_RECORDS > 0

UNION ALL

SELECT *
FROM bz_participants_nulls
WHERE NULL_RECORDS > 0
