{{ config(
    materialized='incremental',
    unique_key='activity_id',
    pre_hook="{{ audit_log_start('go_monthly_user_activity') }}",
    post_hook="{{ audit_log_end('go_monthly_user_activity', 'SUCCESS', 0, 0, 0) }}",
    cluster_by=['activity_month']
) }}

WITH base AS (
    SELECT
        DATE_TRUNC('MONTH', m.START_TIME) AS activity_month,
        u.USER_ID,
        u.COMPANY AS organization_id,
        COUNT(DISTINCT CASE WHEN m.HOST_ID = u.USER_ID THEN m.MEETING_ID END) AS meetings_hosted,
        COUNT(DISTINCT CASE WHEN p.USER_ID = u.USER_ID THEN p.MEETING_ID END) AS meetings_attended,
        SUM(CASE WHEN m.HOST_ID = u.USER_ID THEN COALESCE(m.DURATION_MINUTES,0) ELSE 0 END) AS total_hosting_minutes,
        SUM(DATEDIFF('minute', p.JOIN_TIME, p.LEAVE_TIME)) AS total_attendance_minutes
    FROM ZOOM.SILVER.SV_USERS u
    LEFT JOIN ZOOM.SILVER.SV_MEETINGS m
        ON u.USER_ID = m.HOST_ID
    LEFT JOIN ZOOM.SILVER.SV_PARTICIPANTS p
        ON u.USER_ID = p.USER_ID
    WHERE u.RECORD_STATUS = 'ACTIVE'
    GROUP BY 1,2,3
),
final AS (
    SELECT
        MD5(TO_VARCHAR(activity_month) || USER_ID) AS activity_id,
        activity_month,
        USER_ID,
        organization_id,
        meetings_hosted,
        meetings_attended,
        total_hosting_minutes,
        total_attendance_minutes,
        CURRENT_DATE() AS load_date,
        CURRENT_TIMESTAMP() AS update_date,
        'Silver' AS source_system
    FROM base
)

SELECT * FROM final
{% if is_incremental() %}
WHERE activity_id NOT IN (SELECT activity_id FROM {{ this }})
{% endif %}
