{{ config(severity = 'error') }}

SELECT 
    summary_date,
    organization_id,
    COUNT(*) as record_count
FROM {{ ref('go_daily_meeting_summary') }}
WHERE summary_date IS NULL 
   OR organization_id IS NULL 
   OR total_meetings IS NULL
   OR total_participants IS NULL
GROUP BY summary_date, organization_id
HAVING COUNT(*) > 0