{{ config(
    materialized='incremental',
    unique_key='engagement_id',
    pre_hook="{{ audit_log_start('go_engagement_summary') }}",
    post_hook="{{ audit_log_end('go_engagement_summary', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['summary_date','organization_id']
) }}

WITH meeting_counts AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(DISTINCT m.MEETING_ID) AS total_meetings
    FROM ZOOM.SILVER.SV_MEETINGS m
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE m.RECORD_STATUS = 'VALID'
    GROUP BY 1,2
),
feature_metrics AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        SUM(CASE WHEN f.FEATURE_NAME='chat' THEN f.USAGE_COUNT ELSE 0 END) AS total_chat_messages,
        SUM(CASE WHEN f.FEATURE_NAME='screen_share' THEN f.USAGE_COUNT ELSE 0 END) AS screen_share_sessions,
        SUM(CASE WHEN f.FEATURE_NAME='reactions' THEN f.USAGE_COUNT ELSE 0 END) AS total_reactions,
        SUM(CASE WHEN f.FEATURE_NAME='qa' THEN f.USAGE_COUNT ELSE 0 END) AS qa_interactions,
        SUM(CASE WHEN f.FEATURE_NAME='polls' THEN f.USAGE_COUNT ELSE 0 END) AS poll_responses
    FROM ZOOM.SILVER.SV_FEATURE_USAGE f
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON f.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE f.RECORD_STATUS = 'VALID'
    GROUP BY 1,2
),
participant_metrics AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(p.PARTICIPANT_ID) AS total_participants,
        ROUND(
            SUM(DATEDIFF('minute', p.JOIN_TIME, p.LEAVE_TIME)) / NULLIF(SUM(m.DURATION_MINUTES),0), 2
        ) AS average_attention_score
    FROM ZOOM.SILVER.SV_PARTICIPANTS p
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON p.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE p.RECORD_STATUS = 'ACTIVE'
    GROUP BY 1,2
),
final AS (
    SELECT
        MD5(TO_VARCHAR(m.summary_date) || m.organization_id) AS engagement_id,
        m.summary_date,
        m.organization_id,
        m.total_meetings,
        f.total_chat_messages,
        f.screen_share_sessions,
        f.total_reactions,
        f.qa_interactions,
        f.poll_responses,
        p.average_attention_score,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Silver' AS source_system
    FROM meeting_counts m
    LEFT JOIN feature_metrics f
        ON m.summary_date = f.summary_date
       AND m.organization_id = f.organization_id
    LEFT JOIN participant_metrics p
        ON m.summary_date = p.summary_date
       AND m.organization_id = p.organization_id
)

SELECT * FROM final
{% if is_incremental() %}
WHERE engagement_id NOT IN (SELECT engagement_id FROM {{ this }})
{% endif %}
