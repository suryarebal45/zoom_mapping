-- models/gold/go_monthly_user_activity.sql

{{ config(
    materialized='incremental',
    unique_key='activity_id',
    pre_hook="{{ audit_log_start('go_monthly_user_activity') }}",
    post_hook="{{ audit_log_end('go_monthly_user_activity', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['activity_month']
) }}

SELECT
    UUID_STRING() AS activity_id,
    DATE_TRUNC('MONTH', m.START_TIME) AS activity_month,
    u.USER_ID,
    u.COMPANY AS organization_id,
    COUNT(DISTINCT m.MEETING_ID) FILTER(WHERE m.HOST_ID = u.USER_ID) AS meetings_hosted,
    COUNT(DISTINCT p.MEETING_ID) FILTER(WHERE p.USER_ID = u.USER_ID) AS meetings_attended,
    SUM(COALESCE(m.DURATION_MINUTES,0)) FILTER(WHERE m.HOST_ID = u.USER_ID) AS total_hosting_minutes,
    SUM(DATEDIFF('minute', p.JOIN_TIME, p.LEAVE_TIME)) AS total_attendance_minutes,
    CURRENT_DATE() AS load_date,
    CURRENT_TIMESTAMP() AS update_date,
    'Silver' AS source_system
FROM ZOOM.SILVER.SV_USERS u
LEFT JOIN ZOOM.SILVER.SV_MEETINGS m
    ON u.USER_ID = m.HOST_ID
LEFT JOIN ZOOM.SILVER.SV_PARTICIPANTS p
    ON u.USER_ID = p.USER_ID
WHERE u.RECORD_STATUS = 'ACTIVE'
GROUP BY 2,3,4
