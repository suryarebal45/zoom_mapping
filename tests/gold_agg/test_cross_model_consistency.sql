{{ config(severity = 'warn') }}

WITH daily_totals AS (
    SELECT 
        DATE_TRUNC('MONTH', summary_date) as month_year,
        organization_id,
        SUM(total_meetings) as monthly_meetings_from_daily
    FROM {{ ref('go_daily_meeting_summary') }}
    GROUP BY DATE_TRUNC('MONTH', summary_date), organization_id
),
user_activity_totals AS (
    SELECT 
        activity_month as month_year,
        organization_id,
        SUM(meetings_hosted) as monthly_meetings_from_users
    FROM {{ ref('go_monthly_user_activity') }}
    GROUP BY activity_month, organization_id
)
SELECT 
    d.month_year,
    d.organization_id,
    d.monthly_meetings_from_daily,
    u.monthly_meetings_from_users,
    ABS(d.monthly_meetings_from_daily - COALESCE(u.monthly_meetings_from_users, 0)) as difference
FROM daily_totals d
LEFT JOIN user_activity_totals u ON d.month_year = u.month_year AND d.organization_id = u.organization_id
WHERE ABS(d.monthly_meetings_from_daily - COALESCE(u.monthly_meetings_from_users, 0)) > 10