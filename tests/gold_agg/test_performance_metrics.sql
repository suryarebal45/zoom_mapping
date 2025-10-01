{{ config(severity='warn') }}

WITH volume_check AS (
    SELECT
        'daily_meeting_summary' AS model_name,
        COUNT(*) AS record_count,
        COUNT(DISTINCT summary_date) AS unique_dates,
        COUNT(DISTINCT organization_id) AS unique_orgs
    FROM {{ ref('go_daily_meeting_summary') }}

    UNION ALL

    SELECT
        'monthly_user_activity' AS model_name,
        COUNT(*) AS record_count,
        COUNT(DISTINCT activity_month) AS unique_dates,
        COUNT(DISTINCT organization_id) AS unique_orgs
    FROM {{ ref('monthly_user_activity') }}
)
SELECT *
FROM volume_check
WHERE record_count = 0 OR unique_dates = 0
