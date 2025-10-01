{{ config(severity='warn') }}

WITH date_gaps AS (
    SELECT
        summary_date,
        LAG(summary_date) OVER (ORDER BY summary_date) AS prev_date,
        DATEDIFF('day', LAG(summary_date) OVER (ORDER BY summary_date), summary_date) AS day_gap
    FROM {{ ref('go_daily_meeting_summary') }}
    WHERE summary_date >= CURRENT_DATE - 30
)
SELECT *
FROM date_gaps
WHERE day_gap > 1 AND prev_date IS NOT NULL
