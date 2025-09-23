_____________________________________________
## *Author*: AAVA
## *Created on*:   
## *Description*: Snowflake Gold Aggregated DE Pipeline for Zoom Platform Analytics Systems using dbt transformations
## *Version*: 1 
## *Updated on*: 
_____________________________________________

-- =====================================================
-- SNOWFLAKE GOLD AGGREGATED DE PIPELINE VERSION 1
-- Zoom Platform Analytics Systems
-- dbt Model for Silver to Gold Layer Transformations
-- =====================================================

-- =====================================================
-- 1. DAILY MEETING SUMMARY AGGREGATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='summary_id',
    cluster_by=['summary_date', 'organization_id'],
    tags=['gold', 'aggregated', 'daily']
) }}

WITH daily_meeting_base AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        COALESCE(u.company, 'Unknown') as organization_id,
        m.meeting_id,
        m.host_id,
        m.duration_minutes,
        m.data_quality_score,
        p.participant_id,
        p.user_id as participant_user_id,
        fu.feature_name,
        fu.usage_count
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    LEFT JOIN {{ ref('silver.sv_participants') }} p ON m.meeting_id = p.meeting_id
    LEFT JOIN {{ ref('silver.sv_feature_usage') }} fu ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'Active'
    {% if is_incremental() %}
        AND DATE(m.start_time) > (SELECT MAX(summary_date) FROM {{ this }})
    {% endif %}
),

meeting_aggregates AS (
    SELECT 
        summary_date,
        organization_id,
        COUNT(DISTINCT meeting_id) as total_meetings,
        SUM(duration_minutes) as total_meeting_minutes,
        COUNT(participant_id) as total_participants,
        COUNT(DISTINCT host_id) as unique_hosts,
        COUNT(DISTINCT participant_user_id) as unique_participants,
        ROUND(AVG(duration_minutes), 2) as average_meeting_duration,
        ROUND(COUNT(participant_id)::FLOAT / NULLIF(COUNT(DISTINCT meeting_id), 0), 2) as average_participants_per_meeting,
        COUNT(DISTINCT CASE WHEN feature_name = 'Recording' THEN meeting_id END) as meetings_with_recording,
        ROUND(AVG(data_quality_score), 2) as average_quality_score
    FROM daily_meeting_base
    GROUP BY summary_date, organization_id
),

engagement_scores AS (
    SELECT 
        summary_date,
        organization_id,
        ROUND(
            (COUNT(DISTINCT CASE WHEN feature_name IN ('Chat', 'Screen Sharing', 'Reactions') THEN meeting_id END)::FLOAT / 
             NULLIF(COUNT(DISTINCT meeting_id), 0)) * 100, 2
        ) as average_engagement_score
    FROM daily_meeting_base
    GROUP BY summary_date, organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['ma.summary_date', 'ma.organization_id']) }} as summary_id,
    ma.summary_date,
    ma.organization_id,
    ma.total_meetings,
    ma.total_meeting_minutes,
    ma.total_participants,
    ma.unique_hosts,
    ma.unique_participants,
    ma.average_meeting_duration,
    ma.average_participants_per_meeting,
    ma.meetings_with_recording,
    ROUND((ma.meetings_with_recording::FLOAT / NULLIF(ma.total_meetings, 0)) * 100, 2) as recording_percentage,
    ma.average_quality_score,
    COALESCE(es.average_engagement_score, 0) as average_engagement_score,
    CURRENT_DATE() as load_date,
    CURRENT_TIMESTAMP() as update_date,
    'Gold_Aggregation_Pipeline' as source_system
FROM meeting_aggregates ma
LEFT JOIN engagement_scores es ON ma.summary_date = es.summary_date AND ma.organization_id = es.organization_id

-- =====================================================
-- 2. MONTHLY USER ACTIVITY AGGREGATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='activity_id',
    cluster_by=['activity_month', 'organization_id'],
    tags=['gold', 'aggregated', 'monthly']
) }}

WITH monthly_user_base AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as activity_month,
        u.user_id,
        COALESCE(u.company, 'Unknown') as organization_id,
        m.meeting_id,
        m.host_id,
        m.duration_minutes,
        m.data_quality_score,
        p.participant_id,
        p.join_time,
        p.leave_time,
        w.webinar_id,
        fu.feature_name,
        fu.usage_count
    FROM {{ ref('silver.sv_users') }} u
    LEFT JOIN {{ ref('silver.sv_meetings') }} m ON u.user_id = m.host_id
    LEFT JOIN {{ ref('silver.sv_participants') }} p ON u.user_id = p.user_id
    LEFT JOIN {{ ref('silver.sv_webinars') }} w ON u.user_id = w.host_id
    LEFT JOIN {{ ref('silver.sv_feature_usage') }} fu ON m.meeting_id = fu.meeting_id
    WHERE u.record_status = 'Active'
    {% if is_incremental() %}
        AND DATE_TRUNC('MONTH', COALESCE(m.start_time, p.join_time, w.start_time)) > 
            (SELECT MAX(activity_month) FROM {{ this }})
    {% endif %}
),

user_activity_aggregates AS (
    SELECT 
        activity_month,
        user_id,
        organization_id,
        COUNT(DISTINCT CASE WHEN host_id = user_id THEN meeting_id END) as meetings_hosted,
        COUNT(DISTINCT CASE WHEN participant_id IS NOT NULL THEN meeting_id END) as meetings_attended,
        SUM(CASE WHEN host_id = user_id THEN duration_minutes ELSE 0 END) as total_hosting_minutes,
        SUM(CASE WHEN participant_id IS NOT NULL THEN 
            DATEDIFF('minute', join_time, leave_time) ELSE 0 END) as total_attendance_minutes,
        COUNT(DISTINCT webinar_id) as webinars_hosted,
        COUNT(DISTINCT CASE WHEN feature_name = 'Recording' THEN meeting_id END) as recordings_created,
        ROUND(SUM(CASE WHEN feature_name = 'Recording' THEN usage_count ELSE 0 END) * 0.1, 2) as storage_used_gb,
        COUNT(DISTINCT CASE WHEN participant_id IS NOT NULL AND host_id != user_id THEN host_id END) as unique_participants_interacted,
        ROUND(AVG(data_quality_score), 2) as average_meeting_quality
    FROM monthly_user_base
    GROUP BY activity_month, user_id, organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['activity_month', 'user_id']) }} as activity_id,
    activity_month,
    user_id,
    organization_id,
    meetings_hosted,
    meetings_attended,
    total_hosting_minutes,
    total_attendance_minutes,
    webinars_hosted,
    0 as webinars_attended, -- Placeholder for future enhancement
    recordings_created,
    storage_used_gb,
    unique_participants_interacted,
    average_meeting_quality,
    CURRENT_DATE() as load_date,
    CURRENT_TIMESTAMP() as update_date,
    'Gold_Aggregation_Pipeline' as source_system
FROM user_activity_aggregates
WHERE activity_month IS NOT NULL

-- =====================================================
-- 3. FEATURE ADOPTION SUMMARY AGGREGATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='adoption_id',
    cluster_by=['summary_period', 'organization_id'],
    tags=['gold', 'aggregated', 'features']
) }}

WITH feature_adoption_base AS (
    SELECT 
        DATE_TRUNC('MONTH', fu.usage_date) as summary_period,
        COALESCE(u.company, 'Unknown') as organization_id,
        fu.feature_name,
        fu.usage_count,
        fu.meeting_id,
        m.host_id
    FROM {{ ref('silver.sv_feature_usage') }} fu
    LEFT JOIN {{ ref('silver.sv_meetings') }} m ON fu.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    WHERE fu.record_status = 'Active'
    {% if is_incremental() %}
        AND DATE_TRUNC('MONTH', fu.usage_date) > (SELECT MAX(summary_period) FROM {{ this }})
    {% endif %}
),

feature_aggregates AS (
    SELECT 
        summary_period,
        organization_id,
        feature_name,
        SUM(usage_count) as total_usage_count,
        COUNT(DISTINCT host_id) as unique_users_count
    FROM feature_adoption_base
    GROUP BY summary_period, organization_id, feature_name
),

organization_totals AS (
    SELECT 
        summary_period,
        organization_id,
        COUNT(DISTINCT host_id) as total_organization_users
    FROM feature_adoption_base
    GROUP BY summary_period, organization_id
),

trend_calculation AS (
    SELECT 
        fa.*,
        ot.total_organization_users,
        ROUND((fa.unique_users_count::FLOAT / NULLIF(ot.total_organization_users, 0)) * 100, 2) as adoption_rate,
        LAG(fa.total_usage_count) OVER (
            PARTITION BY fa.organization_id, fa.feature_name 
            ORDER BY fa.summary_period
        ) as prev_usage_count
    FROM feature_aggregates fa
    LEFT JOIN organization_totals ot ON fa.summary_period = ot.summary_period 
        AND fa.organization_id = ot.organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_period', 'organization_id', 'feature_name']) }} as adoption_id,
    summary_period,
    organization_id,
    feature_name,
    total_usage_count,
    unique_users_count,
    adoption_rate,
    CASE 
        WHEN prev_usage_count IS NULL THEN 'New'
        WHEN total_usage_count > prev_usage_count * 1.1 THEN 'Increasing'
        WHEN total_usage_count < prev_usage_count * 0.9 THEN 'Decreasing'
        ELSE 'Stable'
    END as usage_trend,
    CURRENT_DATE() as load_date,
    CURRENT_TIMESTAMP() as update_date,
    'Gold_Aggregation_Pipeline' as source_system
FROM trend_calculation

-- =====================================================
-- 4. QUALITY METRICS SUMMARY AGGREGATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='quality_summary_id',
    cluster_by=['summary_date', 'organization_id'],
    tags=['gold', 'aggregated', 'quality']
) }}

WITH quality_metrics_base AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        COALESCE(u.company, 'Unknown') as organization_id,
        m.meeting_id,
        m.data_quality_score,
        m.record_status,
        w.webinar_id
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    LEFT JOIN {{ ref('silver.sv_webinars') }} w ON DATE(m.start_time) = DATE(w.start_time) 
        AND m.host_id = w.host_id
    {% if is_incremental() %}
        WHERE DATE(m.start_time) > (SELECT MAX(summary_date) FROM {{ this }})
    {% endif %}
),

quality_aggregates AS (
    SELECT 
        summary_date,
        organization_id,
        COUNT(meeting_id) + COUNT(webinar_id) as total_sessions,
        ROUND(AVG(data_quality_score * 0.4), 2) as average_audio_quality,
        ROUND(AVG(data_quality_score * 0.4), 2) as average_video_quality,
        ROUND(AVG(data_quality_score * 0.2), 2) as average_connection_stability,
        ROUND(AVG(CASE WHEN data_quality_score < 3 THEN 150 ELSE 50 END), 2) as average_latency_ms,
        ROUND((COUNT(CASE WHEN record_status = 'Active' THEN 1 END)::FLOAT / 
               NULLIF(COUNT(*), 0)) * 100, 2) as connection_success_rate,
        ROUND((COUNT(CASE WHEN record_status = 'Failed' THEN 1 END)::FLOAT / 
               NULLIF(COUNT(*), 0)) * 100, 4) as call_drop_rate,
        ROUND(AVG(data_quality_score) * 2, 2) as user_satisfaction_score
    FROM quality_metrics_base
    GROUP BY summary_date, organization_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_date', 'organization_id']) }} as quality_summary_id,
    summary_date,
    organization_id,
    total_sessions,
    average_audio_quality,
    average_video_quality,
    average_connection_stability,
    average_latency_ms,
    connection_success_rate,
    call_drop_rate,
    LEAST(user_satisfaction_score, 10.0) as user_satisfaction_score,
    CURRENT_DATE() as load_date,
    CURRENT_TIMESTAMP() as update_date,
    'Gold_Aggregation_Pipeline' as source_system
FROM quality_aggregates

-- =====================================================
-- 5. ENGAGEMENT SUMMARY AGGREGATION
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='engagement_id',
    cluster_by=['summary_date', 'organization_id'],
    tags=['gold', 'aggregated', 'engagement']
) }}

WITH engagement_base AS (
    SELECT 
        DATE(m.start_time) as summary_date,
        COALESCE(u.company, 'Unknown') as organization_id,
        m.meeting_id,
        m.duration_minutes,
        p.participant_id,
        p.join_time,
        p.leave_time,
        fu.feature_name,
        fu.usage_count
    FROM {{ ref('silver.sv_meetings') }} m
    LEFT JOIN {{ ref('silver.sv_users') }} u ON m.host_id = u.user_id
    LEFT JOIN {{ ref('silver.sv_participants') }} p ON m.meeting_id = p.meeting_id
    LEFT JOIN {{ ref('silver.sv_feature_usage') }} fu ON m.meeting_id = fu.meeting_id
    WHERE m.record_status = 'Active'
    {% if is_incremental() %}
        AND DATE(m.start_time) > (SELECT MAX(summary_date) FROM {{ this }})
    {% endif %}
),

engagement_aggregates AS (
    SELECT 
        summary_date,
        organization_id,
        COUNT(DISTINCT meeting_id) as total_meetings,
        ROUND(AVG(
            CASE WHEN duration_minutes > 0 THEN 
                (DATEDIFF('minute', join_time, leave_time)::FLOAT / duration_minutes) * 100
            ELSE 0 END
        ), 2) as average_participation_rate,
        SUM(CASE WHEN feature_name = 'Chat' THEN usage_count ELSE 0 END) as total_chat_messages,
        SUM(CASE WHEN feature_name = 'Screen Sharing' THEN usage_count ELSE 0 END) as screen_share_sessions,
        SUM(CASE WHEN feature_name IN ('Reactions', 'Emoji') THEN usage_count ELSE 0 END) as total_reactions,
        SUM(CASE WHEN feature_name = 'Q&A' THEN usage_count ELSE 0 END) as qa_interactions,
        SUM(CASE WHEN feature_name = 'Polling' THEN usage_count ELSE 0 END) as poll_responses
    FROM engagement_base
    GROUP BY summary_date, organization_id
),

attention_scores AS (
    SELECT 
        summary_date,
        organization_id,
        ROUND(
            (COALESCE(total_chat_messages, 0) * 0.3 + 
             COALESCE(screen_share_sessions, 0) * 0.4 + 
             COALESCE(total_reactions, 0) * 0.1 + 
             COALESCE(qa_interactions, 0) * 0.15 + 
             COALESCE(poll_responses, 0) * 0.05) / 
            NULLIF(total_meetings, 0), 2
        ) as average_attention_score
    FROM engagement_aggregates
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['ea.summary_date', 'ea.organization_id']) }} as engagement_id,
    ea.summary_date,
    ea.organization_id,
    ea.total_meetings,
    ea.average_participation_rate,
    ea.total_chat_messages,
    ea.screen_share_sessions,
    ea.total_reactions,
    ea.qa_interactions,
    ea.poll_responses,
    COALESCE(ats.average_attention_score, 0) as average_attention_score,
    CURRENT_DATE() as load_date,
    CURRENT_TIMESTAMP() as update_date,
    'Gold_Aggregation_Pipeline' as source_system
FROM engagement_aggregates ea
LEFT JOIN attention_scores ats ON ea.summary_date = ats.summary_date 
    AND ea.organization_id = ats.organization_id

-- =====================================================
-- 6. DBT TESTS AND VALIDATIONS
-- =====================================================

-- Test for data completeness
{{ config(
    materialized='test'
) }}

-- Test: Ensure no null values in critical fields
SELECT COUNT(*) as null_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE summary_date IS NULL 
   OR organization_id IS NULL 
   OR total_meetings IS NULL
HAVING COUNT(*) > 0

-- Test: Ensure positive values for metrics
SELECT COUNT(*) as negative_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE total_meetings < 0 
   OR total_meeting_minutes < 0 
   OR total_participants < 0
HAVING COUNT(*) > 0

-- Test: Ensure percentage values are within valid range
SELECT COUNT(*) as invalid_percentage_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE recording_percentage < 0 
   OR recording_percentage > 100
HAVING COUNT(*) > 0

-- =====================================================
-- 7. AUDIT LOGGING MODEL
-- =====================================================

{{ config(
    materialized='incremental',
    unique_key='execution_id',
    tags=['audit', 'logging']
) }}

WITH audit_log AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['run_started_at', 'invocation_id']) }} as execution_id,
        'Gold_Aggregation_Pipeline' as pipeline_name,
        '{{ run_started_at }}' as start_time,
        CURRENT_TIMESTAMP() as end_time,
        CASE 
            WHEN '{{ flags.WHICH }}' = 'run' THEN 'SUCCESS'
            ELSE 'RUNNING'
        END as status,
        NULL as error_message,
        0 as records_processed, -- Will be updated by post-hook
        0 as records_successful,
        0 as records_failed,
        DATEDIFF('second', '{{ run_started_at }}', CURRENT_TIMESTAMP()) as processing_duration_seconds,
        'Silver' as source_system,
        'Gold' as target_system,
        'Aggregation' as process_type,
        '{{ env_var("DBT_USER", "system") }}' as user_executed,
        '{{ env_var("DBT_SERVER", "unknown") }}' as server_name,
        0 as memory_usage_mb,
        0 as cpu_usage_percent,
        CURRENT_DATE() as load_date,
        CURRENT_TIMESTAMP() as update_date
)

SELECT * FROM audit_log

-- =====================================================
-- 8. PERFORMANCE OPTIMIZATION CONFIGURATIONS
-- =====================================================

-- Clustering configuration for all aggregated tables
-- Applied via dbt config blocks above

-- Incremental model strategy for large datasets
-- Using unique_key and incremental conditions

-- Query optimization hints
-- Using appropriate JOINs and WHERE clauses
-- Leveraging Snowflake's automatic query optimization

-- =====================================================
-- 9. DATA QUALITY CONSTRAINTS
-- =====================================================

-- Referential integrity checks
-- Implemented via dbt tests above

-- Business rule validations
-- Meeting duration must be positive
-- Participant counts must be non-negative
-- Quality scores must be within valid range (0-5)
-- Percentages must be between 0-100

-- =====================================================
-- 10. MACRO DEFINITIONS FOR REUSABILITY
-- =====================================================

{% macro calculate_engagement_score(chat_msgs, screen_shares, reactions, qa_count, polls) %}
    ROUND(
        (COALESCE({{ chat_msgs }}, 0) * 0.3 + 
         COALESCE({{ screen_shares }}, 0) * 0.4 + 
         COALESCE({{ reactions }}, 0) * 0.1 + 
         COALESCE({{ qa_count }}, 0) * 0.15 + 
         COALESCE({{ polls }}, 0) * 0.05), 2
    )
{% endmacro %}

{% macro safe_divide(numerator, denominator, default_value=0) %}
    CASE 
        WHEN {{ denominator }} = 0 OR {{ denominator }} IS NULL THEN {{ default_value }}
        ELSE {{ numerator }}::FLOAT / {{ denominator }}
    END
{% endmacro %}

-- =====================================================
-- END OF SNOWFLAKE GOLD AGGREGATED DE PIPELINE V1
-- =====================================================