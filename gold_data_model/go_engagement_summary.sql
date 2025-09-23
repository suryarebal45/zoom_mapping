{{ config(
    materialized='incremental',
    unique_key='engagement_id',
    cluster_by=['summary_date', 'organization_id'],
    on_schema_change='fail'
) }}

WITH engagement_base AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        u.company as organization_id,
        m.meeting_id,
        m.duration_minutes,
        COUNT(p.participant_id) as total_participants,
        AVG(DATEDIFF('minute', p.join_time, COALESCE(p.leave_time, m.end_time))) as avg_participation_duration
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    LEFT JOIN {{ source('silver', 'sv_participants') }} p 
        ON m.meeting_id = p.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE(m.start_time), u.company, m.meeting_id, m.duration_minutes
),

feature_engagement AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        u.company as organization_id,
        SUM(CASE WHEN fu.feature_name = 'chat' THEN fu.usage_count ELSE 0 END) as total_chat_messages,
        SUM(CASE WHEN fu.feature_name = 'screen_share' THEN fu.usage_count ELSE 0 END) as screen_share_sessions,
        SUM(CASE WHEN fu.feature_name = 'reactions' THEN fu.usage_count ELSE 0 END) as total_reactions,
        SUM(CASE WHEN fu.feature_name = 'qa' THEN fu.usage_count ELSE 0 END) as qa_interactions,
        SUM(CASE WHEN fu.feature_name = 'polls' THEN fu.usage_count ELSE 0 END) as poll_responses
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    LEFT JOIN {{ source('silver', 'sv_feature_usage') }} fu 
        ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE(m.start_time), u.company
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as engagement_id,
    eb.summary_date,
    eb.organization_id,
    COUNT(DISTINCT eb.meeting_id) as total_meetings,
    AVG(eb.avg_participation_duration / eb.duration_minutes * 100) as average_participation_rate,
    COALESCE(fe.total_chat_messages, 0) as total_chat_messages,
    COALESCE(fe.screen_share_sessions, 0) as screen_share_sessions,
    COALESCE(fe.total_reactions, 0) as total_reactions,
    COALESCE(fe.qa_interactions, 0) as qa_interactions,
    COALESCE(fe.poll_responses, 0) as poll_responses,
    AVG(eb.avg_participation_duration / eb.duration_minutes * 100) as average_attention_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_PLATFORM' as source_system
FROM engagement_base eb
LEFT JOIN feature_engagement fe 
    ON eb.summary_date = fe.summary_date 
    AND eb.organization_id = fe.organization_id
GROUP BY eb.summary_date, eb.organization_id, 
         fe.total_chat_messages, fe.screen_share_sessions, fe.total_reactions, 
         fe.qa_interactions, fe.poll_responses;
