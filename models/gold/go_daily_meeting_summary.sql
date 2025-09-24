-- models/gold/go_daily_meeting_summary.sql

{{ config(
    materialized='incremental',
    unique_key='summary_id',
    pre_hook="{{ audit_log_start('go_daily_meeting_summary') }}",
    post_hook="{{ audit_log_end('go_daily_meeting_summary', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['summary_date']
) }}

WITH meeting_data AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(DISTINCT m.MEETING_ID) AS total_meetings,
        SUM(COALESCE(m.DURATION_MINUTES,0)) AS total_meeting_minutes,
        COUNT(DISTINCT m.HOST_ID) AS unique_hosts
    FROM ZOOM.SILVER.SV_MEETINGS m
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE m.RECORD_STATUS = 'ACTIVE' 
      AND COALESCE(m.DATA_QUALITY_SCORE,0) >= 0.7
    GROUP BY 1,2
),
participant_data AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(p.PARTICIPANT_ID) AS total_participants,
        COUNT(DISTINCT p.USER_ID) AS unique_participants
    FROM ZOOM.SILVER.SV_PARTICIPANTS p
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON p.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE p.RECORD_STATUS = 'ACTIVE'
    GROUP BY 1,2
)

SELECT
    UUID_STRING() AS summary_id,
    d.summary_date,
    d.organization_id,
    d.total_meetings,
    d.total_meeting_minutes,
    p.total_participants,
    d.unique_hosts,
    p.unique_participants,
    ROUND(SAFE_DIVIDE(d.total_meeting_minutes, NULLIF(d.total_meetings,0)),2) AS average_meeting_duration,
    ROUND(SAFE_DIVIDE(p.total_participants, NULLIF(d.total_meetings,0)),2) AS average_participants_per_meeting,
    CURRENT_DATE() AS load_date,
    CURRENT_TIMESTAMP() AS update_date,
    'Silver' AS source_system
FROM meeting_data d
LEFT JOIN participant_data p
    ON d.summary_date = p.summary_date
   AND d.organization_id = p.organization_id
