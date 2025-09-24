-- models/gold/go_quality_metrics_summary.sql

{{ config(
    materialized='incremental',
    unique_key='quality_summary_id',
    pre_hook="{{ audit_log_start('go_quality_metrics_summary') }}",
    post_hook="{{ audit_log_end('go_quality_metrics_summary', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['summary_date','organization_id']
) }}

WITH meeting_metrics AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(DISTINCT m.MEETING_ID) AS total_sessions,
        AVG(CASE WHEN m.QUALITY_TYPE='audio' THEN m.DATA_QUALITY_SCORE END) AS average_audio_quality,
        AVG(CASE WHEN m.QUALITY_TYPE='video' THEN m.DATA_QUALITY_SCORE END) AS average_video_quality,
        CURRENT_DATE() AS load_date
    FROM ZOOM.SILVER.SV_MEETINGS m
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE m.RECORD_STATUS = 'ACTIVE'
      AND COALESCE(m.DATA_QUALITY_SCORE,0) >= 0.7
    GROUP BY 1,2
),
connection_metrics AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        ROUND(SAFE_DIVIDE(
            COUNT(p.PARTICIPANT_ID) FILTER(WHERE p.LEAVE_TIME IS NOT NULL), 
            COUNT(p.PARTICIPANT_ID)
        ) * 100,2) AS connection_success_rate,
        ROUND(SAFE_DIVIDE(
            COUNT(p.PARTICIPANT_ID) FILTER(WHERE p.LEAVE_TIME < m.END_TIME), 
            COUNT(p.PARTICIPANT_ID)
        ) * 100,2) AS call_drop_rate
    FROM ZOOM.SILVER.SV_PARTICIPANTS p
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON p.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE p.RECORD_STATUS = 'ACTIVE'
    GROUP BY 1,2
)

SELECT
    UUID_STRING() AS quality_summary_id,
    m.summary_date,
    m.organization_id,
    m.total_sessions,
    m.average_audio_quality,
    m.average_video_quality,
    c.connection_success_rate,
    c.call_drop_rate,
    CURRENT_DATE() AS update_date,
    m.load_date,
    'Silver' AS source_system
FROM meeting_metrics m
LEFT JOIN connection_metrics c
    ON m.summary_date = c.summary_date
   AND m.organization_id = c.organization_id
