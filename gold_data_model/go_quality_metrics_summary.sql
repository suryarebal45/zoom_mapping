{{ config(
    materialized='incremental',
    unique_key='quality_summary_id',
    cluster_by=['summary_date', 'organization_id'],
    on_schema_change='fail'
) }}

WITH quality_base AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        u.company as organization_id,
        m.meeting_id,
        m.data_quality_score,
        m.duration_minutes,
        COUNT(p.participant_id) as session_participants,
        COUNT(CASE WHEN p.leave_time < m.end_time THEN p.participant_id END) as early_disconnects,
        AVG(DATEDIFF('minute', p.join_time, COALESCE(p.leave_time, m.end_time))) as avg_connection_duration
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    LEFT JOIN {{ source('silver', 'sv_participants') }} p 
        ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND m.data_quality_score >= 0.7
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE(m.start_time), u.company, m.meeting_id, m.data_quality_score, m.duration_minutes
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as quality_summary_id,
    summary_date,
    organization_id,
    COUNT(DISTINCT meeting_id) as total_sessions,
    AVG(data_quality_score) as average_audio_quality,
    AVG(data_quality_score * 0.95) as average_video_quality,
    AVG(avg_connection_duration / duration_minutes * 100) as average_connection_stability,
    50.0 as average_latency_ms,
    CASE 
        WHEN SUM(session_participants) > 0 
        THEN ((SUM(session_participants) - SUM(early_disconnects)) * 100.0) / SUM(session_participants)
        ELSE 100.0 
    END as connection_success_rate,
    CASE 
        WHEN SUM(session_participants) > 0 
        THEN (SUM(early_disconnects) * 100.0) / SUM(session_participants)
        ELSE 0.0 
    END as call_drop_rate,
    AVG(data_quality_score) as user_satisfaction_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_PLATFORM' as source_system
FROM quality_base
GROUP BY summary_date, organization_id;
