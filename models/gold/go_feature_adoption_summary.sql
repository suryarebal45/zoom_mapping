{{ config(
    materialized='incremental',
    unique_key='adoption_id',
    pre_hook="{{ audit_log_start('go_feature_adoption_summary') }}",
    post_hook="{{ audit_log_end('go_feature_adoption_summary', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['summary_period']
) }}

WITH base AS (
    SELECT
        DATE_TRUNC('MONTH', usage_date) AS summary_period,
        u.COMPANY AS organization_id,
        f.FEATURE_NAME,
        SUM(f.USAGE_COUNT) AS total_usage_count,
        COUNT(DISTINCT m.HOST_ID) AS unique_users_count
    FROM ZOOM.SILVER.SV_FEATURE_USAGE f
    JOIN ZOOM.SILVER.SV_MEETINGS m
        ON f.MEETING_ID = m.MEETING_ID
    JOIN ZOOM.SILVER.SV_USERS u
        ON m.HOST_ID = u.USER_ID
    WHERE f.RECORD_STATUS = 'ACTIVE'
    GROUP BY 1,2,3
),
final AS (
    SELECT
        MD5(TO_VARCHAR(summary_period) || organization_id || FEATURE_NAME) AS adoption_id,
        summary_period,
        organization_id,
        FEATURE_NAME,
        total_usage_count,
        unique_users_count,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Silver' AS source_system
    FROM base
)

SELECT * FROM final
{% if is_incremental() %}
WHERE adoption_id NOT IN (SELECT adoption_id FROM {{ this }})
{% endif %}
