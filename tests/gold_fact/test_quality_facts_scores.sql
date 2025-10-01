-- tests/test_quality_facts_scores.sql
{{ config(severity = 'error') }}

SELECT 
    quality_fact_id,
    COUNT(*) as violation_count
FROM {{ ref('go_quality_facts') }}
WHERE audio_quality_score < 0 
   OR audio_quality_score > 5
   OR video_quality_score < 0
   OR video_quality_score > 5
   OR connection_stability_rating < 0
   OR connection_stability_rating > 5
GROUP BY quality_fact_id
HAVING COUNT(*) > 0
