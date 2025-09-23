{{ config(
    materialized='incremental',
    unique_key='activity_id',
    cluster_by=['activity_month', 'organization_id'],
    on_schema_change='fail'
) }}

WITH monthly_hosting_activity AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as activity_month,
        m.host_id as user_id,
        u.company as organization_id,
        COUNT(DISTINCT m.meeting_id) as meetings_hosted,
        SUM(m.duration_minutes) as total_hosting_minutes,
        AVG(m.data_quality_score) as average_meeting_quality,
        COUNT(CASE WHEN fu.feature_name = 'recording' AND fu.usage_count > 0 
              THEN m.meeting_id END) as recordings_created
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    LEFT JOIN {{ source('silver', 'sv_feature_usage') }} fu 
        ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND m.data_quality_score >= 0.7
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', m.start_time), m.host_id, u.company
),

monthly_participation_activity AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as activity_month,
        p.user_id,
        u.company as organization_id,
        COUNT(DISTINCT p.meeting_id) as meetings_attended,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) as total_attendance_minutes
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_participants') }} p 
        ON m.meeting_id = p.meeting_id
    JOIN {{ source('silver', 'sv_users') }} u 
        ON p.user_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND p.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND p.join_time IS NOT NULL
        AND p.leave_time IS NOT NULL
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', m.start_time), p.user_id, u.company
),

monthly_webinar_activity AS (
    SELECT 
        DATE_TRUNC('MONTH', w.start_time) as activity_month,
        w.host_id as user_id,
        u.company as organization_id,
        COUNT(DISTINCT w.webinar_id) as webinars_hosted
    FROM {{ source('silver', 'sv_webinars') }} w
    JOIN {{ source('silver', 'sv_users') }} u 
        ON w.host_id = u.user_id
    WHERE w.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND w.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', w.start_time), w.host_id, u.company
),

unique_interactions AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as activity_month,
        m.host_id as user_id,
        u.company as organization_id,
        COUNT(DISTINCT p.user_id) as unique_participants_interacted
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_participants') }} p 
        ON m.meeting_id = p.meeting_id
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND p.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', m.start_time), m.host_id, u.company
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['activity_month', 'user_id', 'organization_id']) }} as activity_id,
    COALESCE(mha.activity_month, mpa.activity_month, mwa.activity_month) as activity_month,
    COALESCE(mha.user_id, mpa.user_id, mwa.user_id) as user_id,
    COALESCE(mha.organization_id, mpa.organization_id, mwa.organization_id) as organization_id,
    COALESCE(mha.meetings_hosted, 0) as meetings_hosted,
    COALESCE(mpa.meetings_attended, 0) as meetings_attended,
    COALESCE(mha.total_hosting_minutes, 0) as total_hosting_minutes,
    COALESCE(mpa.total_attendance_minutes, 0) as total_attendance_minutes,
    COALESCE(mwa.webinars_hosted, 0) as webinars_hosted,
    0 as webinars_attended,
    COALESCE(mha.recordings_created, 0) as recordings_created,
    0.0 as storage_used_gb,
    COALESCE(ui.unique_participants_interacted, 0) as unique_participants_interacted,
    COALESCE(mha.average_meeting_quality, 0) as average_meeting_quality,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_PLATFORM' as source_system
FROM monthly_hosting_activity mha
FULL OUTER JOIN monthly_participation_activity mpa 
    ON mha.activity_month = mpa.activity_month 
    AND mha.user_id = mpa.user_id 
    AND mha.organization_id = mpa.organization_id
FULL OUTER JOIN monthly_webinar_activity mwa 
    ON COALESCE(mha.activity_month, mpa.activity_month) = mwa.activity_month 
    AND COALESCE(mha.user_id, mpa.user_id) = mwa.user_id 
    AND COALESCE(mha.organization_id, mpa.organization_id) = mwa.organization_id
LEFT JOIN unique_interactions ui 
    ON COALESCE(mha.activity_month, mpa.activity_month, mwa.activity_month) = ui.activity_month 
    AND COALESCE(mha.user_id, mpa.user_id, mwa.user_id) = ui.user_id 
    AND COALESCE(mha.organization_id, mpa.organization_id, mwa.organization_id) = ui.organization_id;
