{{ config(
    materialized='incremental',
    unique_key='summary_id',
    cluster_by=['summary_date', 'organization_id'],
    on_schema_change='sync_all_columns'
) }}

WITH daily_meeting_base AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        u.company AS organization_id,
        m.meeting_id,
        m.host_id,
        m.duration_minutes,
        m.data_quality_score,
        m.load_date,
        m.source_system
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u
        ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND m.data_quality_score >= 0.7
        AND m.duration_minutes > 0
        {% if is_incremental() %}
        -- Only pick new rows since last load
        AND m.load_date > COALESCE((SELECT MAX(load_date) FROM {{ this }}), '1900-01-01')
        {% endif %}
),

participant_counts AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        u.company AS organization_id,
        COUNT(p.participant_id) AS total_participants,
        COUNT(DISTINCT p.user_id) AS unique_participants,
        AVG(DATEDIFF('minute', p.join_time, p.leave_time)) AS avg_participation_duration
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u
        ON m.host_id = u.user_id
    JOIN {{ source('silver', 'sv_participants') }} p
        ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND p.record_status = 'ACTIVE'
        AND p.join_time IS NOT NULL
        AND p.leave_time IS NOT NULL
        {% if is_incremental() %}
        AND m.load_date > COALESCE((SELECT MAX(load_date) FROM {{ this }}), '1900-01-01')
        {% endif %}
    GROUP BY DATE(m.start_time), u.company
),

recording_metrics AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        u.company AS organization_id,
        COUNT(CASE WHEN fu.feature_name = 'recording' AND fu.usage_count > 0 THEN m.meeting_id END) AS meetings_with_recording
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u
        ON m.host_id = u.user_id
    LEFT JOIN {{ source('silver', 'sv_feature_usage') }} fu
        ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND m.load_date > COALESCE((SELECT MAX(load_date) FROM {{ this }}), '1900-01-01')
        {% endif %}
    GROUP BY DATE(m.start_time), u.company
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['dmb.summary_date','dmb.organization_id']) }} AS summary_id,
    dmb.summary_date,
    dmb.organization_id,
    COUNT(DISTINCT dmb.meeting_id) AS total_meetings,
    SUM(dmb.duration_minutes) AS total_meeting_minutes,
    COALESCE(MAX(pc.total_participants), 0) AS total_participants,
    COUNT(DISTINCT dmb.host_id) AS unique_hosts,
    COALESCE(MAX(pc.unique_participants), 0) AS unique_participants,
    AVG(dmb.duration_minutes) AS average_meeting_duration,
    CASE 
        WHEN COUNT(DISTINCT dmb.meeting_id) > 0 THEN COALESCE(MAX(pc.total_participants),0)/COUNT(DISTINCT dmb.meeting_id)
        ELSE 0 
    END AS average_participants_per_meeting,
    COALESCE(MAX(rm.meetings_with_recording), 0) AS meetings_with_recording,
    CASE 
        WHEN COUNT(DISTINCT dmb.meeting_id) > 0 THEN (COALESCE(MAX(rm.meetings_with_recording),0)*100.0)/COUNT(DISTINCT dmb.meeting_id)
        ELSE 0 
    END AS recording_percentage,
    AVG(dmb.data_quality_score) AS average_quality_score,
    COALESCE(MAX(pc.avg_participation_duration)/NULLIF(AVG(dmb.duration_minutes),0)*100,0) AS average_engagement_score,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    MAX(dmb.source_system) AS source_system
FROM daily_meeting_base dmb
LEFT JOIN participant_counts pc
    ON dmb.summary_date = pc.summary_date 
    AND dmb.organization_id = pc.organization_id
LEFT JOIN recording_metrics rm
    ON dmb.summary_date = rm.summary_date 
    AND dmb.organization_id = rm.organization_id
GROUP BY dmb.summary_date, dmb.organization_id
ORDER BY dmb.summary_date, dmb.organization_id
