{{ config(
    materialized='incremental',
    unique_key='summary_id',
    pre_hook="{{ audit_log_start('go_daily_meeting_summary') }}",
    post_hook="{{ audit_log_end('go_daily_meeting_summary', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['summary_date']
) }}

-- ------------------------------
-- CTE 1: Aggregate Meeting Data
-- ------------------------------
WITH meeting_data AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(DISTINCT m.MEETING_ID) AS total_meetings,
        SUM(COALESCE(m.DURATION_MINUTES,0)) AS total_meeting_minutes,
        COUNT(DISTINCT m.HOST_ID) AS unique_hosts
    FROM {{ source('silver', 'sv_meetings') }} AS m
    JOIN {{ source('silver', 'sv_users') }} AS u
        ON m.HOST_ID = u.USER_ID
    WHERE m.RECORD_STATUS = 'VALID'
      AND COALESCE(m.DATA_QUALITY_SCORE,0) >= 0.7
      AND m.START_TIME IS NOT NULL
      AND u.COMPANY IS NOT NULL
    GROUP BY 1,2
),

-- ---------------------------------
-- CTE 2: Aggregate Participant Data
-- ---------------------------------
participant_data AS (
    SELECT
        DATE(m.START_TIME) AS summary_date,
        u.COMPANY AS organization_id,
        COUNT(p.PARTICIPANT_ID) AS total_participants,
        COUNT(DISTINCT p.USER_ID) AS unique_participants
    FROM {{ source('silver', 'sv_participants') }} AS p
    JOIN {{ source('silver', 'sv_meetings') }} AS m
        ON p.MEETING_ID = m.MEETING_ID
    JOIN {{ source('silver', 'sv_users') }} AS u
        ON m.HOST_ID = u.USER_ID
    WHERE p.RECORD_STATUS = 'VALID'
      AND m.START_TIME IS NOT NULL
      AND u.COMPANY IS NOT NULL
    GROUP BY 1,2
),

-- ------------------------------
-- CTE 3: Combine Meeting & Participant Data
-- ------------------------------
final AS (
    SELECT
        MD5(TO_VARCHAR(d.summary_date) || d.organization_id) AS summary_id,
        d.summary_date,
        d.organization_id,
        COALESCE(d.total_meetings,0) AS total_meetings,
        COALESCE(d.total_meeting_minutes,0) AS total_meeting_minutes,
        COALESCE(p.total_participants,0) AS total_participants,
        COALESCE(d.unique_hosts,0) AS unique_hosts,
        COALESCE(p.unique_participants,0) AS unique_participants,
        ROUND(COALESCE(d.total_meeting_minutes,0) / NULLIF(COALESCE(d.total_meetings,0),0),2) AS average_meeting_duration,
        ROUND(COALESCE(p.total_participants,0) / NULLIF(COALESCE(d.total_meetings,0),0),2) AS average_participants_per_meeting,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Silver' AS source_system
    FROM meeting_data d
    LEFT JOIN participant_data p
        ON d.summary_date = p.summary_date
       AND d.organization_id = p.organization_id
)

-- ------------------------------
-- Final Incremental Load
-- ------------------------------
SELECT *
FROM final
{% if is_incremental() %}
WHERE summary_id NOT IN (SELECT summary_id FROM {{ this }})
{% endif %}
