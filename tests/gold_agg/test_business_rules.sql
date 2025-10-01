SELECT *
FROM {{ ref('go_daily_meeting_summary') }}
WHERE total_meetings < 0
   OR total_meeting_minutes < 0
   OR total_participants < 0
   OR unique_hosts < 0
   OR unique_participants < 0
