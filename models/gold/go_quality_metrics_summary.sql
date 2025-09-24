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
        AVG(COALESCE(m.DATA_QUALITY_SCORE,0)) AS average_quality_score,
        CURRENT_DATE() AS load_date
    FROM ZOOM.SILVER.SV_MEETINGS m
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE m.RECORD_STATUS = 'VALID'
      AND COALESCE(m.DATA_QUALITY_SCORE,0) >= 0.7
    GROUP BY 1,2
),
connection_metrics AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        ROUND(
            CASE WHEN COUNT(p.PARTICIPANT_ID)=0 THEN NULL
                 ELSE COUNT(CASE WHEN p.LEAVE_TIME IS NOT NULL THEN 1 END) / COUNT(p.PARTICIPANT_ID) * 100
            END, 2
        ) AS connection_success_rate,
        ROUND(
            CASE WHEN COUNT(p.PARTICIPANT_ID)=0 THEN NULL
                 ELSE COUNT(CASE WHEN p.LEAVE_TIME < m.END_TIME THEN 1 END) / COUNT(p.PARTICIPANT_ID) * 100
            END, 2
        ) AS call_drop_rate
    FROM ZOOM.SILVER.SV_PARTICIPANTS p
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON p.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE p.RECORD_STATUS = 'VALID'
    GROUP BY 1,2
),
final AS (
    SELECT
        MD5(TO_VARCHAR(m.summary_date) || m.organization_id) AS quality_summary_id,
        m.summary_date,
        m.organization_id,
        m.total_sessions,
        m.average_quality_score,
        c.connection_success_rate,
        c.call_drop_rate,
        CURRENT_DATE() AS update_date,
        m.load_date,
        'Silver' AS source_system
    FROM meeting_metrics m
    LEFT JOIN connection_metrics c
        ON m.summary_date = c.summary_date
       AND m.organization_id = c.organization_id
)

SELECT * FROM final
{% if is_incremental() %}
WHERE quality_summary_id NOT IN (SELECT quality_summary_id FROM {{ this }})
{% endif %}
