{{ config(
    materialized='incremental',
    unique_key='adoption_id',
    cluster_by=['summary_period', 'organization_id'],
    on_schema_change='fail'
) }}

WITH feature_usage_base AS (
    SELECT 
        DATE_TRUNC('MONTH', fu.usage_date) as summary_period,
        u.company as organization_id,
        fu.feature_name,
        SUM(fu.usage_count) as total_usage_count,
        COUNT(DISTINCT m.host_id) as unique_users_count,
        fu.load_date,
        fu.source_system
    FROM {{ source('silver', 'sv_feature_usage') }} fu
    JOIN {{ source('silver', 'sv_meetings') }} m 
        ON fu.meeting_id = m.meeting_id
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    WHERE fu.record_status = 'ACTIVE'
        AND m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        AND fu.usage_count > 0
        {% if is_incremental() %}
        AND fu.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', fu.usage_date), u.company, fu.feature_name, fu.load_date, fu.source_system
),

total_active_users AS (
    SELECT 
        DATE_TRUNC('MONTH', m.start_time) as summary_period,
        u.company as organization_id,
        COUNT(DISTINCT m.host_id) as total_active_users
    FROM {{ source('silver', 'sv_meetings') }} m
    JOIN {{ source('silver', 'sv_users') }} u 
        ON m.host_id = u.user_id
    WHERE m.record_status = 'ACTIVE'
        AND u.record_status = 'ACTIVE'
        {% if is_incremental() %}
        AND m.load_date > (SELECT MAX(load_date) FROM {{ this }})
        {% endif %}
    GROUP BY DATE_TRUNC('MONTH', m.start_time), u.company
),

feature_trends AS (
    SELECT 
        summary_period,
        organization_id,
        feature_name,
        total_usage_count,
        LAG(total_usage_count) OVER (
            PARTITION BY organization_id, feature_name 
            ORDER BY summary_period
        ) as previous_month_usage
    FROM feature_usage_base
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['summary_period', 'organization_id', 'feature_name']) }} as adoption_id,
    fub.summary_period,
    fub.organization_id,
    fub.feature_name,
    fub.total_usage_count,
    fub.unique_users_count,
    CASE 
        WHEN tau.total_active_users > 0 
        THEN (fub.unique_users_count * 100.0) / tau.total_active_users
        ELSE 0 
    END as adoption_rate,
    CASE 
        WHEN ft.previous_month_usage IS NULL THEN 'New'
        WHEN ft.total_usage_count > ft.previous_month_usage THEN 'Increasing'
        WHEN ft.total_usage_count < ft.previous_month_usage THEN 'Decreasing'
        ELSE 'Stable'
    END as usage_trend,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    FIRST_VALUE(fub.source_system) as source_system
FROM feature_usage_base fub
LEFT JOIN total_active_users tau 
    ON fub.summary_period = tau.summary_period 
    AND fub.organization_id = tau.organization_id
LEFT JOIN feature_trends ft 
    ON fub.summary_period = ft.summary_period 
    AND fub.organization_id = ft.organization_id 
    AND fub.feature_name = ft.feature_name;
