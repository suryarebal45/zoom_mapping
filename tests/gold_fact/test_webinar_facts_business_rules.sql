-- tests/test_webinar_facts_business_rules.sql
{{ config(severity = 'warn') }}

SELECT 
    webinar_fact_id,
    COUNT(*) as violation_count
FROM {{ ref('go_webinar_facts') }}
WHERE attendance_rate < 0 
   OR attendance_rate > 100
   OR actual_attendees > registrants_count
GROUP BY webinar_fact_id
HAVING COUNT(*) > 0
