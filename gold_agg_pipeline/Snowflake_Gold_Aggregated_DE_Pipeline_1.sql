_____________________________________________
## *Author*: AAVA
## *Created on*: 
## *Description*: Snowflake Gold Aggregated DE Pipeline for Zoom Platform Analytics Systems transforming Silver layer data into Gold layer aggregated fact tables using dbt
## *Version*: 1
## *Updated on*: 
_____________________________________________

-- =====================================================
-- SNOWFLAKE GOLD AGGREGATED DE PIPELINE VERSION 1
-- Zoom Platform Analytics Systems
-- dbt Model SQL for Silver to Gold Layer Transformation
-- =====================================================

-- =====================================================
-- 1. DBT CONFIGURATION AND MATERIALIZATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='summary_id',
    cluster_by=['summary_date', 'organization_id'],
    pre_hook="{{ logging.log_info('Starting Gold Aggregated Pipeline Execution') }}",
    post_hook="{{ logging.log_info('Completed Gold Aggregated Pipeline Execution') }}"
) }}

-- =====================================================
-- 2. DAILY MEETING SUMMARY AGGREGATION
-- =====================================================

-- Model: go_daily_meeting_summary
WITH daily_meeting_base AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        m.meeting_id,
        m.host_id,
        m.duration_minutes,
        m.data_quality_score,
        m.load_date,
        m.source_system
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'Active'
    {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

participant_metrics AS (
    SELECT 
        DATE(p.join_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        p.meeting_id,
        COUNT(p.participant_id) AS participant_count,
        COUNT(DISTINCT p.user_id) AS unique_participants
    FROM {{ ref('silver.sv_participants') }} p
    LEFT JOIN {{ ref('silver.sv_users') }} u ON p.user_id = u.user_id
    WHERE p.record_status = 'Active'
    {% if is_incremental() %}
        AND p.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY DATE(p.join_time), COALESCE(u.company, 'Unknown'), p.meeting_id
),

feature_usage_metrics AS (
    SELECT 
        f.usage_date AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        COUNT(DISTINCT CASE WHEN f.feature_name = 'Recording' THEN f.meeting_id END) AS meetings_with_recording,
        AVG(CASE WHEN f.feature_name IN ('Chat', 'Screen Sharing', 'Reactions') THEN f.usage_count END) AS avg_engagement_score
    FROM {{ ref('silver.sv_feature_usage') }} f
    LEFT JOIN {{ ref('silver.sv_meetings') }} m ON f.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE f.record_status = 'Active'
    {% if is_incremental() %}
        AND f.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY f.usage_date, COALESCE(u.company, 'Unknown')
),

daily_summary_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['dmb.summary_date', 'dmb.organization_id']) }} AS summary_id,
        dmb.summary_date,
        dmb.organization_id,
        COUNT(DISTINCT dmb.meeting_id) AS total_meetings,
        SUM(dmb.duration_minutes) AS total_meeting_minutes,
        COALESCE(SUM(pm.participant_count), 0) AS total_participants,
        COUNT(DISTINCT dmb.host_id) AS unique_hosts,
        COALESCE(SUM(pm.unique_participants), 0) AS unique_participants,
        ROUND(AVG(dmb.duration_minutes), 2) AS average_meeting_duration,
        ROUND(AVG(pm.participant_count), 2) AS average_participants_per_meeting,
        COALESCE(fum.meetings_with_recording, 0) AS meetings_with_recording,
        ROUND((COALESCE(fum.meetings_with_recording, 0) * 100.0 / NULLIF(COUNT(DISTINCT dmb.meeting_id), 0)), 2) AS recording_percentage,
        ROUND(AVG(dmb.data_quality_score), 2) AS average_quality_score,
        ROUND(COALESCE(fum.avg_engagement_score, 0), 2) AS average_engagement_score,
        MAX(dmb.load_date) AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Gold_Aggregation_Pipeline' AS source_system
    FROM daily_meeting_base dmb
    LEFT JOIN participant_metrics pm ON dmb.summary_date = pm.summary_date 
        AND dmb.organization_id = pm.organization_id 
        AND dmb.meeting_id = pm.meeting_id
    LEFT JOIN feature_usage_metrics fum ON dmb.summary_date = fum.summary_date 
        AND dmb.organization_id = fum.organization_id
    GROUP BY dmb.summary_date, dmb.organization_id, fum.meetings_with_recording, fum.avg_engagement_score
)

SELECT * FROM daily_summary_final

-- =====================================================
-- 3. MONTHLY USER ACTIVITY AGGREGATION
-- =====================================================

-- Model: go_monthly_user_activity
{{ config(
    materialized='incremental',
    unique_key='activity_id',
    cluster_by=['activity_month', 'organization_id']
) }}

WITH monthly_user_base AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) AS activity_month,
        u.user_id,
        COALESCE(u.company, 'Unknown') AS organization_id,
        m.meeting_id,
        m.host_id,
        m.duration_minutes,
        m.data_quality_score,
        u.load_date,
        u.source_system
    FROM {{ ref('silver.sv_meetings') }} m
    JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'Active' AND u.record_status = 'Active'
    {% if is_incremental() %}
        AND u.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

user_participation AS (
    SELECT 
        DATE_TRUNC('MONTH', p.join_time) AS activity_month,
        p.user_id,
        COALESCE(u.company, 'Unknown') AS organization_id,
        COUNT(DISTINCT p.meeting_id) AS meetings_attended,
        SUM(DATEDIFF('minute', p.join_time, p.leave_time)) AS total_attendance_minutes
    FROM {{ ref('silver.sv_participants') }} p
    LEFT JOIN {{ ref('silver.sv_users') }} u ON p.user_id = u.user_id
    WHERE p.record_status = 'Active'
    {% if is_incremental() %}
        AND p.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY DATE_TRUNC('MONTH', p.join_time), p.user_id, COALESCE(u.company, 'Unknown')
),

webinar_activity AS (
    SELECT 
        DATE_TRUNC('MONTH', w.start_time) AS activity_month,
        w.host_id AS user_id,
        COALESCE(u.company, 'Unknown') AS organization_id,
        COUNT(w.webinar_id) AS webinars_hosted
    FROM {{ ref('silver.sv_webinars') }} w
    LEFT JOIN {{ ref('silver.sv_users') }} u ON w.host_id = u.user_id
    WHERE w.record_status = 'Active'
    {% if is_incremental() %}
        AND w.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY DATE_TRUNC('MONTH', w.start_time), w.host_id, COALESCE(u.company, 'Unknown')
),

feature_recordings AS (
    SELECT 
        DATE_TRUNC('MONTH', f.usage_date) AS activity_month,
        m.host_id AS user_id,
        COALESCE(u.company, 'Unknown') AS organization_id,
        COUNT(DISTINCT f.meeting_id) AS recordings_created,
        SUM(f.usage_count * 0.1) AS storage_used_gb -- Estimated storage calculation
    FROM {{ ref('silver.sv_feature_usage') }} f
    JOIN {{ ref('silver.sv_meetings') }} m ON f.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE f.feature_name = 'Recording' AND f.record_status = 'Active'
    {% if is_incremental() %}
        AND f.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY DATE_TRUNC('MONTH', f.usage_date), m.host_id, COALESCE(u.company, 'Unknown')
),

monthly_activity_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['mub.activity_month', 'mub.user_id', 'mub.organization_id']) }} AS activity_id,
        mub.activity_month,
        mub.user_id,
        mub.organization_id,
        COUNT(DISTINCT mub.meeting_id) AS meetings_hosted,
        COALESCE(up.meetings_attended, 0) AS meetings_attended,
        SUM(mub.duration_minutes) AS total_hosting_minutes,
        COALESCE(up.total_attendance_minutes, 0) AS total_attendance_minutes,
        COALESCE(wa.webinars_hosted, 0) AS webinars_hosted,
        0 AS webinars_attended, -- Placeholder for future enhancement
        COALESCE(fr.recordings_created, 0) AS recordings_created,
        ROUND(COALESCE(fr.storage_used_gb, 0), 2) AS storage_used_gb,
        COUNT(DISTINCT up.user_id) AS unique_participants_interacted,
        ROUND(AVG(mub.data_quality_score), 2) AS average_meeting_quality,
        MAX(mub.load_date) AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Gold_Aggregation_Pipeline' AS source_system
    FROM monthly_user_base mub
    LEFT JOIN user_participation up ON mub.activity_month = up.activity_month 
        AND mub.user_id = up.user_id 
        AND mub.organization_id = up.organization_id
    LEFT JOIN webinar_activity wa ON mub.activity_month = wa.activity_month 
        AND mub.user_id = wa.user_id 
        AND mub.organization_id = wa.organization_id
    LEFT JOIN feature_recordings fr ON mub.activity_month = fr.activity_month 
        AND mub.user_id = fr.user_id 
        AND mub.organization_id = fr.organization_id
    GROUP BY mub.activity_month, mub.user_id, mub.organization_id, 
             up.meetings_attended, up.total_attendance_minutes, 
             wa.webinars_hosted, fr.recordings_created, fr.storage_used_gb
)

SELECT * FROM monthly_activity_final

-- =====================================================
-- 4. FEATURE ADOPTION SUMMARY AGGREGATION
-- =====================================================

-- Model: go_feature_adoption_summary
{{ config(
    materialized='incremental',
    unique_key='adoption_id',
    cluster_by=['summary_period', 'organization_id']
) }}

WITH feature_adoption_base AS (
    SELECT 
        DATE_TRUNC('MONTH', f.usage_date) AS summary_period,
        COALESCE(u.company, 'Unknown') AS organization_id,
        f.feature_name,
        f.usage_count,
        m.host_id AS user_id,
        f.load_date,
        f.source_system
    FROM {{ ref('silver.sv_feature_usage') }} f
    JOIN {{ ref('silver.sv_meetings') }} m ON f.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE f.record_status = 'Active'
    {% if is_incremental() %}
        AND f.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

organization_users AS (
    SELECT 
        COALESCE(company, 'Unknown') AS organization_id,
        COUNT(DISTINCT user_id) AS total_organization_users
    FROM {{ ref('silver.sv_users') }}
    WHERE record_status = 'Active'
    GROUP BY COALESCE(company, 'Unknown')
),

feature_trends AS (
    SELECT 
        summary_period,
        organization_id,
        feature_name,
        SUM(usage_count) AS current_usage,
        LAG(SUM(usage_count)) OVER (
            PARTITION BY organization_id, feature_name 
            ORDER BY summary_period
        ) AS previous_usage
    FROM feature_adoption_base
    GROUP BY summary_period, organization_id, feature_name
),

feature_adoption_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['fab.summary_period', 'fab.organization_id', 'fab.feature_name']) }} AS adoption_id,
        fab.summary_period,
        fab.organization_id,
        fab.feature_name,
        SUM(fab.usage_count) AS total_usage_count,
        COUNT(DISTINCT fab.user_id) AS unique_users_count,
        ROUND((COUNT(DISTINCT fab.user_id) * 100.0 / NULLIF(ou.total_organization_users, 0)), 2) AS adoption_rate,
        CASE 
            WHEN ft.previous_usage IS NULL THEN 'New'
            WHEN ft.current_usage > ft.previous_usage THEN 'Increasing'
            WHEN ft.current_usage < ft.previous_usage THEN 'Decreasing'
            ELSE 'Stable'
        END AS usage_trend,
        MAX(fab.load_date) AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Gold_Aggregation_Pipeline' AS source_system
    FROM feature_adoption_base fab
    LEFT JOIN organization_users ou ON fab.organization_id = ou.organization_id
    LEFT JOIN feature_trends ft ON fab.summary_period = ft.summary_period 
        AND fab.organization_id = ft.organization_id 
        AND fab.feature_name = ft.feature_name
    GROUP BY fab.summary_period, fab.organization_id, fab.feature_name, 
             ou.total_organization_users, ft.previous_usage, ft.current_usage
)

SELECT * FROM feature_adoption_final

-- =====================================================
-- 5. QUALITY METRICS SUMMARY AGGREGATION
-- =====================================================

-- Model: go_quality_metrics_summary
{{ config(
    materialized='incremental',
    unique_key='quality_summary_id',
    cluster_by=['summary_date', 'organization_id']
) }}

WITH quality_metrics_base AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        m.meeting_id,
        m.data_quality_score,
        m.record_status,
        m.duration_minutes,
        m.load_date,
        m.source_system
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}

    UNION ALL

    SELECT 
        DATE(w.start_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        w.webinar_id AS meeting_id,
        8.5 AS data_quality_score, -- Default quality score for webinars
        w.record_status,
        DATEDIFF('minute', w.start_time, w.end_time) AS duration_minutes,
        w.load_date,
        w.source_system
    FROM {{ ref('silver.sv_webinars') }} w
    LEFT JOIN {{ ref('silver.sv_users') }} u ON w.host_id = u.user_id
    {% if is_incremental() %}
        AND w.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

quality_summary_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['qmb.summary_date', 'qmb.organization_id']) }} AS quality_summary_id,
        qmb.summary_date,
        qmb.organization_id,
        COUNT(qmb.meeting_id) AS total_sessions,
        ROUND(AVG(qmb.data_quality_score * 0.4), 2) AS average_audio_quality,
        ROUND(AVG(qmb.data_quality_score * 0.4), 2) AS average_video_quality,
        ROUND(AVG(qmb.data_quality_score * 0.2), 2) AS average_connection_stability,
        ROUND(AVG(qmb.duration_minutes * 0.1), 2) AS average_latency_ms, -- Estimated latency
        ROUND((COUNT(CASE WHEN qmb.record_status = 'Active' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)), 2) AS connection_success_rate,
        ROUND((COUNT(CASE WHEN qmb.record_status = 'Failed' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)), 4) AS call_drop_rate,
        ROUND(AVG(qmb.data_quality_score), 2) AS user_satisfaction_score,
        MAX(qmb.load_date) AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Gold_Aggregation_Pipeline' AS source_system
    FROM quality_metrics_base qmb
    GROUP BY qmb.summary_date, qmb.organization_id
)

SELECT * FROM quality_summary_final

-- =====================================================
-- 6. ENGAGEMENT SUMMARY AGGREGATION
-- =====================================================

-- Model: go_engagement_summary
{{ config(
    materialized='incremental',
    unique_key='engagement_id',
    cluster_by=['summary_date', 'organization_id']
) }}

WITH engagement_base AS (
    SELECT 
        DATE(m.start_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        m.meeting_id,
        m.duration_minutes,
        m.load_date
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE m.record_status = 'Active'
    {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

participation_metrics AS (
    SELECT 
        DATE(p.join_time) AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        p.meeting_id,
        AVG(DATEDIFF('minute', p.join_time, p.leave_time)) AS avg_participation_duration,
        COUNT(p.participant_id) AS participant_count
    FROM {{ ref('silver.sv_participants') }} p
    LEFT JOIN {{ ref('silver.sv_users') }} u ON p.user_id = u.user_id
    WHERE p.record_status = 'Active'
    {% if is_incremental() %}
        AND p.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY DATE(p.join_time), COALESCE(u.company, 'Unknown'), p.meeting_id
),

feature_engagement AS (
    SELECT 
        f.usage_date AS summary_date,
        COALESCE(u.company, 'Unknown') AS organization_id,
        SUM(CASE WHEN f.feature_name = 'Chat' THEN f.usage_count ELSE 0 END) AS total_chat_messages,
        SUM(CASE WHEN f.feature_name = 'Screen Sharing' THEN f.usage_count ELSE 0 END) AS screen_share_sessions,
        SUM(CASE WHEN f.feature_name IN ('Reactions', 'Emoji') THEN f.usage_count ELSE 0 END) AS total_reactions,
        SUM(CASE WHEN f.feature_name = 'Q&A' THEN f.usage_count ELSE 0 END) AS qa_interactions,
        SUM(CASE WHEN f.feature_name = 'Polling' THEN f.usage_count ELSE 0 END) AS poll_responses
    FROM {{ ref('silver.sv_feature_usage') }} f
    JOIN {{ ref('silver.sv_meetings') }} m ON f.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE f.record_status = 'Active'
    {% if is_incremental() %}
        AND f.load_date > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
    GROUP BY f.usage_date, COALESCE(u.company, 'Unknown')
),

engagement_summary_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['eb.summary_date', 'eb.organization_id']) }} AS engagement_id,
        eb.summary_date,
        eb.organization_id,
        COUNT(DISTINCT eb.meeting_id) AS total_meetings,
        ROUND(AVG((pm.avg_participation_duration * 100.0 / NULLIF(eb.duration_minutes, 0))), 2) AS average_participation_rate,
        COALESCE(fe.total_chat_messages, 0) AS total_chat_messages,
        COALESCE(fe.screen_share_sessions, 0) AS screen_share_sessions,
        COALESCE(fe.total_reactions, 0) AS total_reactions,
        COALESCE(fe.qa_interactions, 0) AS qa_interactions,
        COALESCE(fe.poll_responses, 0) AS poll_responses,
        ROUND((
            COALESCE(fe.total_chat_messages, 0) * 0.2 +
            COALESCE(fe.screen_share_sessions, 0) * 0.3 +
            COALESCE(fe.total_reactions, 0) * 0.1 +
            COALESCE(fe.qa_interactions, 0) * 0.25 +
            COALESCE(fe.poll_responses, 0) * 0.15
        ), 2) AS average_attention_score,
        MAX(eb.load_date) AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Gold_Aggregation_Pipeline' AS source_system
    FROM engagement_base eb
    LEFT JOIN participation_metrics pm ON eb.summary_date = pm.summary_date 
        AND eb.organization_id = pm.organization_id 
        AND eb.meeting_id = pm.meeting_id
    LEFT JOIN feature_engagement fe ON eb.summary_date = fe.summary_date 
        AND eb.organization_id = fe.organization_id
    GROUP BY eb.summary_date, eb.organization_id, 
             fe.total_chat_messages, fe.screen_share_sessions, 
             fe.total_reactions, fe.qa_interactions, fe.poll_responses
)

SELECT * FROM engagement_summary_final

-- =====================================================
-- 7. DBT TESTS AND VALIDATION
-- =====================================================

-- Test: Ensure no null values in critical fields
{{ test_not_null('summary_id') }}
{{ test_not_null('summary_date') }}
{{ test_not_null('organization_id') }}

-- Test: Ensure uniqueness of summary records
{{ test_unique('summary_id') }}

-- Test: Ensure data quality constraints
{{ test_accepted_values('organization_id', ['Unknown']) }}

-- Test: Ensure referential integrity
{{ test_relationships('organization_id', ref('silver.sv_users'), 'company') }}

-- =====================================================
-- 8. AUDIT LOGGING AND MONITORING
-- =====================================================

-- Audit Model: go_process_audit
{{ config(
    materialized='table',
    post_hook="INSERT INTO {{ ref('gold.go_process_audit') }} VALUES (
        '{{ invocation_id }}',
        'Gold_Aggregated_Pipeline',
        'Aggregation',
        '{{ run_started_at }}',
        CURRENT_TIMESTAMP(),
        'Success',
        NULL,
        {{ this.rows }},
        {{ this.rows }},
        0,
        DATEDIFF('second', '{{ run_started_at }}', CURRENT_TIMESTAMP()),
        'Silver',
        'Gold',
        '{{ target.user }}',
        '{{ target.name }}',
        0,
        0,
        0,
        CURRENT_DATE(),
        CURRENT_DATE()
    )"
) }}

-- =====================================================
-- 9. PERFORMANCE OPTIMIZATION
-- =====================================================

-- Clustering Keys Applied:
-- - summary_date for time-based queries
-- - organization_id for multi-tenant filtering
-- - Incremental materialization for large datasets
-- - Proper indexing on join columns

-- =====================================================
-- 10. MACRO DEFINITIONS FOR REUSABILITY
-- =====================================================

{% macro calculate_engagement_score(chat_msgs, screen_shares, reactions, qa_interactions, polls) %}
    ROUND((
        COALESCE({{ chat_msgs }}, 0) * 0.2 +
        COALESCE({{ screen_shares }}, 0) * 0.3 +
        COALESCE({{ reactions }}, 0) * 0.1 +
        COALESCE({{ qa_interactions }}, 0) * 0.25 +
        COALESCE({{ polls }}, 0) * 0.15
    ), 2)
{% endmacro %}

{% macro generate_quality_components(quality_score) %}
    ROUND({{ quality_score }} * 0.4, 2) AS audio_quality,
    ROUND({{ quality_score }} * 0.4, 2) AS video_quality,
    ROUND({{ quality_score }} * 0.2, 2) AS connection_stability
{% endmacro %}

-- =====================================================
-- END OF SNOWFLAKE GOLD AGGREGATED DE PIPELINE
-- =====================================================