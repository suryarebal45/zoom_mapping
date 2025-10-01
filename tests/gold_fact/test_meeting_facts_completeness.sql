-- tests/test_meeting_facts_completeness.sql
{{ config(severity = 'error') }}

SELECT 
    meeting_id,
    COUNT(*) as record_count
FROM {{ ref('go_meeting_facts') }}
WHERE meeting_id IS NULL
   OR host_id IS NULL
   OR start_time IS NULL
   OR end_time IS NULL
GROUP BY meeting_id
HAVING COUNT(*) > 0
