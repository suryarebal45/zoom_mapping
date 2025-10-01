-- Validate weekend calculation logic
SELECT 
    date_key,
    day_of_week,
    is_weekend
FROM {{ ref('go_time_dimension') }}
WHERE (
    (day_of_week IN (0, 6) AND is_weekend = FALSE) OR
    (day_of_week NOT IN (0, 6) AND is_weekend = TRUE)
)
